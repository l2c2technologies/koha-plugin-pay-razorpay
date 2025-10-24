package Koha::Plugin::Com::L2C2::RazorPay;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Auth qw( get_template_and_user );
use C4::Context;
use C4::Members;
use Koha::Account;
use Koha::Account::Lines;
use Koha::Patron::Categories;
use Koha::Patrons;
use Koha::Libraries;

use CGI qw( -utf8 );
use JSON qw( decode_json encode_json );
use LWP::UserAgent;
use Digest::SHA qw( hmac_sha256_hex );
use MIME::Base64;
use PDF::API2;
use DateTime;
use Try::Tiny;

## Here we set our plugin version
our $VERSION = "{VERSION}";
our $MINIMUM_VERSION = '24.05.00.000';

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'RazorPay OPAC Payment Plugin',
    author          => 'L2C2 Technologies',
    date_authored   => '2025-10-24',
    date_updated    => "1970-01-01",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin enables online OPAC payments via RazorPay payment gateway for Indian libraries. Supports modal checkout, partial payments, webhooks, and comprehensive transaction logging.',
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a very poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'report.tt' } );

    my $dbh = C4::Context->dbh;
    
    # Get filter parameters
    my $date_from = $cgi->param('date_from') || '';
    my $date_to = $cgi->param('date_to') || '';
    my $status = $cgi->param('status') || '';
    my $borrowernumber = $cgi->param('borrowernumber') || '';

    # Build query
    my $query = q{
        SELECT 
            t.transaction_id,
            t.borrowernumber,
            CONCAT(p.surname, ', ', p.firstname) as patron_name,
            p.cardnumber,
            t.amount_paid,
            t.razorpay_order_id,
            t.razorpay_payment_id,
            t.razorpay_signature,
            t.status,
            t.payment_method,
            t.created_at,
            t.updated_at,
            t.error_message
        FROM rzp_transactions t
        LEFT JOIN borrowers p ON t.borrowernumber = p.borrowernumber
        WHERE 1=1
    };

    my @params;
    
    if ($date_from) {
        $query .= " AND DATE(t.created_at) >= ?";
        push @params, $date_from;
    }
    
    if ($date_to) {
        $query .= " AND DATE(t.created_at) <= ?";
        push @params, $date_to;
    }
    
    if ($status) {
        $query .= " AND t.status = ?";
        push @params, $status;
    }
    
    if ($borrowernumber) {
        $query .= " AND t.borrowernumber = ?";
        push @params, $borrowernumber;
    }
    
    $query .= " ORDER BY t.created_at DESC";

    my $sth = $dbh->prepare($query);
    $sth->execute(@params);
    
    my @transactions;
    while ( my $row = $sth->fetchrow_hashref ) {
        push @transactions, $row;
    }

    $template->param(
        transactions => \@transactions,
        date_from => $date_from,
        date_to => $date_to,
        status => $status,
        borrowernumber => $borrowernumber,
    );

    $self->output_html( $template->output() );
}

## If your tool is complicated enough to needs it's own setting/configuration
## you will want to add a 'configure' method to your plugin like so.
## Here I am throwing all the logic into the 'configure' method, but it could
## be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            enable_opac_payments => $self->retrieve_data('enable_opac_payments') || '0',
            test_mode => $self->retrieve_data('test_mode') || '0',
            
            # Test credentials
            test_key_id => $self->retrieve_data('test_key_id') || '',
            test_key_secret => $self->retrieve_data('test_key_secret') || '',
            test_webhook_secret => $self->retrieve_data('test_webhook_secret') || '',
            
            # Live credentials
            live_key_id => $self->retrieve_data('live_key_id') || '',
            live_key_secret => $self->retrieve_data('live_key_secret') || '',
            live_webhook_secret => $self->retrieve_data('live_webhook_secret') || '',
            
            # Payment settings
            min_payment_amount => $self->retrieve_data('min_payment_amount') || '1.00',
            max_payment_amount => $self->retrieve_data('max_payment_amount') || '',
            enable_partial_payment => $self->retrieve_data('enable_partial_payment') || '0',
            partial_payment_type => $self->retrieve_data('partial_payment_type') || 'percentage',
            partial_payment_value => $self->retrieve_data('partial_payment_value') || '',
            
            # Branding
            business_name => $self->retrieve_data('business_name') || C4::Context->preference('LibraryName'),
            business_logo => $self->retrieve_data('business_logo') || '',
            theme_color => $self->retrieve_data('theme_color') || '#528FF0',
            
            # Notifications
            enable_custom_receipt => $self->retrieve_data('enable_custom_receipt') || '0',
            receipt_email_from => $self->retrieve_data('receipt_email_from') || C4::Context->preference('KohaAdminEmailAddress'),
            
            # GST & Compliance
            enable_gst => $self->retrieve_data('enable_gst') || '0',
            gstin => $self->retrieve_data('gstin') || '',
            enable_institutional_reporting => $self->retrieve_data('enable_institutional_reporting') || '0',
        );

        $self->output_html( $template->output() );
    }
    else {
        # Save all configuration
        $self->store_data(
            {
                enable_opac_payments => $cgi->param('enable_opac_payments') || '0',
                test_mode => $cgi->param('test_mode') || '0',
                
                # Test credentials
                test_key_id => $cgi->param('test_key_id') || '',
                test_key_secret => $cgi->param('test_key_secret') || '',
                test_webhook_secret => $cgi->param('test_webhook_secret') || '',
                
                # Live credentials
                live_key_id => $cgi->param('live_key_id') || '',
                live_key_secret => $cgi->param('live_key_secret') || '',
                live_webhook_secret => $cgi->param('live_webhook_secret') || '',
                
                # Payment settings
                min_payment_amount => $cgi->param('min_payment_amount') || '1.00',
                max_payment_amount => $cgi->param('max_payment_amount') || '',
                enable_partial_payment => $cgi->param('enable_partial_payment') || '0',
                partial_payment_type => $cgi->param('partial_payment_type') || 'percentage',
                partial_payment_value => $cgi->param('partial_payment_value') || '',
                
                # Branding
                business_name => $cgi->param('business_name') || C4::Context->preference('LibraryName'),
                business_logo => $cgi->param('business_logo') || '',
                theme_color => $cgi->param('theme_color') || '#528FF0',
                
                # Notifications
                enable_custom_receipt => $cgi->param('enable_custom_receipt') || '0',
                receipt_email_from => $cgi->param('receipt_email_from') || C4::Context->preference('KohaAdminEmailAddress'),
                
                # GST & Compliance
                enable_gst => $cgi->param('enable_gst') || '0',
                gstin => $cgi->param('gstin') || '',
                enable_institutional_reporting => $cgi->param('enable_institutional_reporting') || '0',
                
                last_configured => DateTime->now->datetime(),
            }
        );
        $self->go_home();
    }
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;

    # Create rzp_transactions table
    my $transactions_table = $dbh->do(q{
        CREATE TABLE IF NOT EXISTS rzp_transactions (
            transaction_id INT(11) NOT NULL AUTO_INCREMENT,
            borrowernumber INT(11) NOT NULL,
            amount_paid DECIMAL(28,6) NOT NULL,
            razorpay_order_id VARCHAR(100) DEFAULT NULL,
            razorpay_payment_id VARCHAR(100) DEFAULT NULL,
            razorpay_signature VARCHAR(255) DEFAULT NULL,
            status ENUM('created', 'attempted', 'paid', 'failed', 'refunded', 'cancelled') NOT NULL DEFAULT 'created',
            payment_method VARCHAR(50) DEFAULT NULL,
            accountlines_ids TEXT DEFAULT NULL,
            api_request TEXT DEFAULT NULL,
            api_response TEXT DEFAULT NULL,
            error_message TEXT DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (transaction_id),
            INDEX idx_borrowernumber (borrowernumber),
            INDEX idx_razorpay_order_id (razorpay_order_id),
            INDEX idx_razorpay_payment_id (razorpay_payment_id),
            INDEX idx_status (status),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    });

    # Create error logs table
    my $error_logs_table = $dbh->do(q{
        CREATE TABLE IF NOT EXISTS rzp_error_logs (
            log_id INT(11) NOT NULL AUTO_INCREMENT,
            transaction_id INT(11) DEFAULT NULL,
            error_type ENUM('api_error', 'webhook_error', 'validation_error', 'system_error') NOT NULL,
            error_code VARCHAR(50) DEFAULT NULL,
            error_message TEXT NOT NULL,
            request_data TEXT DEFAULT NULL,
            response_data TEXT DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (log_id),
            INDEX idx_transaction_id (transaction_id),
            INDEX idx_error_type (error_type),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    });

    return $transactions_table && $error_logs_table;
}

## This is the 'upgrade' method. It will be triggered when a newer version of a
## plugin is installed over an existing older version of a plugin
sub upgrade {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;
    
    # Add any schema upgrades here for future versions
    # Example:
    # my $dt = DateTime->now();
    # $self->store_data( { last_upgraded => $dt->datetime() } );

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall {
    my ( $self, $args ) = @_;

    # We don't drop the tables on uninstall to preserve transaction history
    # Administrators can manually drop tables if needed:
    # DROP TABLE IF EXISTS rzp_transactions;
    # DROP TABLE IF EXISTS rzp_error_logs;

    return 1;
}

## API methods called by opac scripts

## This method initiates the payment process
sub opac_online_payment_begin {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $borrowernumber = $args->{borrowernumber};
    my @accountlines_ids = $cgi->multi_param('accountline');
    my $payment_amount = $cgi->param('payment_amount');

    # Verify plugin is enabled
    unless ( $self->retrieve_data('enable_opac_payments') ) {
        return $self->_error_page("Online payments are currently disabled. Please contact the library.");
    }

    # Get patron
    my $patron = Koha::Patrons->find($borrowernumber);
    unless ($patron) {
        return $self->_error_page("Invalid patron.");
    }

    # Get accountlines
    my @accountlines;
    my $total_due = 0;
    
    if (@accountlines_ids) {
        foreach my $id (@accountlines_ids) {
            my $accountline = Koha::Account::Lines->find($id);
            if ($accountline && $accountline->borrowernumber == $borrowernumber) {
                push @accountlines, $accountline;
                $total_due += $accountline->amountoutstanding;
            }
        }
    } else {
        # Get all outstanding fines
        @accountlines = Koha::Account::Lines->search({
            borrowernumber => $borrowernumber,
            amountoutstanding => { '>' => 0 }
        })->as_list;
        
        foreach my $line (@accountlines) {
            $total_due += $line->amountoutstanding;
        }
    }

    unless (@accountlines) {
        return $self->_error_page("No outstanding charges found.");
    }

    # Validate payment amount
    my $min_amount = $self->retrieve_data('min_payment_amount') || 1.00;
    my $max_amount = $self->retrieve_data('max_payment_amount') || 0;
    
    # If no payment_amount specified, use total due
    $payment_amount = $total_due unless $payment_amount;
    
    # Apply partial payment rules
    if ( $self->retrieve_data('enable_partial_payment') ) {
        my $partial_type = $self->retrieve_data('partial_payment_type') || 'percentage';
        my $partial_value = $self->retrieve_data('partial_payment_value') || 0;
        
        if ($partial_value) {
            my $min_partial;
            if ($partial_type eq 'percentage') {
                $min_partial = ($total_due * $partial_value) / 100;
            } else {
                $min_partial = $partial_value;
            }
            $min_amount = $min_partial if $min_partial > $min_amount;
        }
    }
    
    if ($payment_amount < $min_amount) {
        return $self->_error_page("Payment amount cannot be less than ₹$min_amount");
    }
    
    if ($max_amount > 0 && $payment_amount > $max_amount) {
        return $self->_error_page("Payment amount cannot exceed ₹$max_amount");
    }
    
    if ($payment_amount > $total_due) {
        return $self->_error_page("Payment amount cannot exceed total outstanding amount of ₹$total_due");
    }

    # Create RazorPay order
    my $order_result = $self->_create_razorpay_order({
        amount => $payment_amount,
        borrowernumber => $borrowernumber,
        accountlines_ids => [map { $_->id } @accountlines],
    });

    unless ($order_result->{success}) {
        $self->_log_error({
            error_type => 'api_error',
            error_message => $order_result->{error},
            request_data => encode_json($order_result->{request}),
            response_data => $order_result->{response},
        });
        return $self->_error_page("Failed to initiate payment: " . $order_result->{error});
    }

    # Store transaction
    my $transaction_id = $self->_store_transaction({
        borrowernumber => $borrowernumber,
        amount_paid => $payment_amount,
        razorpay_order_id => $order_result->{order_id},
        status => 'created',
        accountlines_ids => encode_json([map { $_->id } @accountlines]),
        api_request => encode_json($order_result->{request}),
        api_response => encode_json($order_result->{response}),
    });

    # Prepare template data
    my $template = $self->get_template({ file => 'opac_online_payment_begin.tt' });

    my $test_mode = $self->retrieve_data('test_mode') || 0;
    my $key_id = $test_mode 
        ? $self->retrieve_data('test_key_id') 
        : $self->retrieve_data('live_key_id');

    $template->param(
        borrowernumber => $borrowernumber,
        patron_name => $patron->firstname . ' ' . $patron->surname,
        cardnumber => $patron->cardnumber,
        accountlines => \@accountlines,
        total_due => sprintf("%.2f", $total_due),
        payment_amount => sprintf("%.2f", $payment_amount),
        transaction_id => $transaction_id,
        razorpay_order_id => $order_result->{order_id},
        razorpay_key_id => $key_id,
        business_name => $self->retrieve_data('business_name') || C4::Context->preference('LibraryName'),
        business_logo => $self->retrieve_data('business_logo') || '',
        theme_color => $self->retrieve_data('theme_color') || '#528FF0',
        test_mode => $test_mode,
        opac_url => C4::Context->preference('OPACBaseURL'),
    );

    return $self->output_html( $template->output() );
}

## This method handles the payment callback
sub opac_online_payment_end {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $razorpay_payment_id = $cgi->param('razorpay_payment_id');
    my $razorpay_order_id = $cgi->param('razorpay_order_id');
    my $razorpay_signature = $cgi->param('razorpay_signature');
    my $transaction_id = $cgi->param('transaction_id');

    # Verify signature
    my $signature_valid = $self->_verify_payment_signature({
        order_id => $razorpay_order_id,
        payment_id => $razorpay_payment_id,
        signature => $razorpay_signature,
    });

    unless ($signature_valid) {
        $self->_update_transaction({
            transaction_id => $transaction_id,
            status => 'failed',
            error_message => 'Invalid payment signature',
        });
        
        $self->_log_error({
            transaction_id => $transaction_id,
            error_type => 'validation_error',
            error_message => 'Payment signature verification failed',
            request_data => encode_json({
                razorpay_payment_id => $razorpay_payment_id,
                razorpay_order_id => $razorpay_order_id,
                razorpay_signature => $razorpay_signature,
            }),
        });
        
        return $self->_error_page("Payment verification failed. Please contact the library.");
    }

    # Get payment details from RazorPay
    my $payment_details = $self->_fetch_payment_details($razorpay_payment_id);
    
    unless ($payment_details->{success}) {
        return $self->_error_page("Failed to retrieve payment details.");
    }

    # Get transaction from database
    my $transaction = $self->_get_transaction($transaction_id);
    unless ($transaction) {
        return $self->_error_page("Transaction not found.");
    }

    # Process payment in Koha
    my $payment_result = $self->_process_koha_payment({
        transaction_id => $transaction_id,
        borrowernumber => $transaction->{borrowernumber},
        amount => $transaction->{amount_paid},
        razorpay_payment_id => $razorpay_payment_id,
        razorpay_order_id => $razorpay_order_id,
        payment_method => $payment_details->{method},
        accountlines_ids => decode_json($transaction->{accountlines_ids}),
    });

    if ($payment_result->{success}) {
        # Update transaction
        $self->_update_transaction({
            transaction_id => $transaction_id,
            razorpay_payment_id => $razorpay_payment_id,
            razorpay_signature => $razorpay_signature,
            payment_method => $payment_details->{method},
            status => 'paid',
            api_response => encode_json($payment_details->{data}),
        });

        # Send custom receipt if enabled
        if ($self->retrieve_data('enable_custom_receipt')) {
            $self->_send_payment_receipt({
                transaction_id => $transaction_id,
                borrowernumber => $transaction->{borrowernumber},
            });
        }

        # Redirect to success page
        my $template = $self->get_template({ file => 'opac_online_payment_end.tt' });
        
        my $patron = Koha::Patrons->find($transaction->{borrowernumber});
        
        $template->param(
            success => 1,
            transaction_id => $transaction_id,
            razorpay_payment_id => $razorpay_payment_id,
            amount_paid => sprintf("%.2f", $transaction->{amount_paid}),
            payment_method => $payment_details->{method},
            patron_name => $patron->firstname . ' ' . $patron->surname,
            payment_date => DateTime->now->strftime('%d %B %Y, %I:%M %p'),
        );

        return $self->output_html( $template->output() );
    } else {
        $self->_update_transaction({
            transaction_id => $transaction_id,
            status => 'failed',
            error_message => $payment_result->{error},
        });
        
        return $self->_error_page("Payment processing failed: " . $payment_result->{error});
    }
}

## Webhook handler for RazorPay callbacks
sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'razorpay';
}

## Helper methods

sub _create_razorpay_order {
    my ( $self, $args ) = @_;
    
    my $test_mode = $self->retrieve_data('test_mode') || 0;
    my $key_id = $test_mode 
        ? $self->retrieve_data('test_key_id') 
        : $self->retrieve_data('live_key_id');
    my $key_secret = $test_mode 
        ? $self->retrieve_data('test_key_secret') 
        : $self->retrieve_data('live_key_secret');

    # Amount must be in paise (multiply by 100)
    my $amount_paise = int($args->{amount} * 100);

    my $order_data = {
        amount => $amount_paise,
        currency => 'INR',
        receipt => 'rcpt_' . $args->{borrowernumber} . '_' . time(),
        notes => {
            borrowernumber => $args->{borrowernumber},
            accountlines => join(',', @{$args->{accountlines_ids}}),
        }
    };

    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);

    my $auth = encode_base64($key_id . ':' . $key_secret, '');

    my $response = $ua->post(
        'https://api.razorpay.com/v1/orders',
        'Authorization' => "Basic $auth",
        'Content-Type' => 'application/json',
        Content => encode_json($order_data),
    );

    if ($response->is_success) {
        my $result = decode_json($response->decoded_content);
        return {
            success => 1,
            order_id => $result->{id},
            request => $order_data,
            response => $response->decoded_content,
        };
    } else {
        return {
            success => 0,
            error => $response->status_line,
            request => $order_data,
            response => $response->decoded_content,
        };
    }
}

sub _verify_payment_signature {
    my ( $self, $args ) = @_;
    
    my $test_mode = $self->retrieve_data('test_mode') || 0;
    my $key_secret = $test_mode 
        ? $self->retrieve_data('test_key_secret') 
        : $self->retrieve_data('live_key_secret');

    my $payload = $args->{order_id} . '|' . $args->{payment_id};
    my $expected_signature = hmac_sha256_hex($payload, $key_secret);

    return $expected_signature eq $args->{signature};
}

sub _fetch_payment_details {
    my ( $self, $payment_id ) = @_;
    
    my $test_mode = $self->retrieve_data('test_mode') || 0;
    my $key_id = $test_mode 
        ? $self->retrieve_data('test_key_id') 
        : $self->retrieve_data('live_key_id');
    my $key_secret = $test_mode 
        ? $self->retrieve_data('test_key_secret') 
        : $self->retrieve_data('live_key_secret');

    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);

    my $auth = encode_base64($key_id . ':' . $key_secret, '');

    my $response = $ua->get(
        "https://api.razorpay.com/v1/payments/$payment_id",
        'Authorization' => "Basic $auth",
    );

    if ($response->is_success) {
        my $result = decode_json($response->decoded_content);
        return {
            success => 1,
            method => $result->{method} || 'unknown',
            data => $result,
        };
    } else {
        return {
            success => 0,
            error => $response->status_line,
        };
    }
}

sub _process_koha_payment {
    my ( $self, $args ) = @_;
    
    try {
        my $patron = Koha::Patrons->find($args->{borrowernumber});
        my $account = $patron->account;
        
        # Get accountlines
        my @lines = Koha::Account::Lines->search({
            accountlines_id => { -in => $args->{accountlines_ids} },
            borrowernumber => $args->{borrowernumber},
        })->as_list;
        
        # Pay the accountlines
        my $library_id = C4::Context->userenv ? C4::Context->userenv->{'branch'} : undef;
        
        my $payment = $account->pay({
            amount => $args->{amount},
            lines => \@lines,
            note => "RazorPay Payment - ID: $args->{razorpay_payment_id}",
            library_id => $library_id,
            payment_type => 'RAZORPAY',
        });
        
        return { success => 1, payment => $payment };
    } catch {
        return { success => 0, error => $_ };
    };
}

sub _store_transaction {
    my ( $self, $args ) = @_;
    
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(q{
        INSERT INTO rzp_transactions 
        (borrowernumber, amount_paid, razorpay_order_id, razorpay_payment_id, razorpay_signature, 
         status, payment_method, accountlines_ids, api_request, api_response, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    });
    
    $sth->execute(
        $args->{borrowernumber},
        $args->{amount_paid},
        $args->{razorpay_order_id},
        $args->{razorpay_payment_id},
        $args->{razorpay_signature},
        $args->{status},
        $args->{payment_method},
        $args->{accountlines_ids},
        $args->{api_request},
        $args->{api_response},
        $args->{error_message},
    );
    
    return $dbh->last_insert_id(undef, undef, 'rzp_transactions', 'transaction_id');
}

sub _update_transaction {
    my ( $self, $args ) = @_;
    
    my $dbh = C4::Context->dbh;
    
    my @fields;
    my @values;
    
    foreach my $key (keys %$args) {
        next if $key eq 'transaction_id';
        push @fields, "$key = ?";
        push @values, $args->{$key};
    }
    
    push @values, $args->{transaction_id};
    
    my $sql = "UPDATE rzp_transactions SET " . join(', ', @fields) . " WHERE transaction_id = ?";
    my $sth = $dbh->prepare($sql);
    $sth->execute(@values);
}

sub _get_transaction {
    my ( $self, $transaction_id ) = @_;
    
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(q{
        SELECT * FROM rzp_transactions WHERE transaction_id = ?
    });
    $sth->execute($transaction_id);
    
    return $sth->fetchrow_hashref;
}

sub _log_error {
    my ( $self, $args ) = @_;
    
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(q{
        INSERT INTO rzp_error_logs 
        (transaction_id, error_type, error_code, error_message, request_data, response_data)
        VALUES (?, ?, ?, ?, ?, ?)
    });
    
    $sth->execute(
        $args->{transaction_id},
        $args->{error_type},
        $args->{error_code},
        $args->{error_message},
        $args->{request_data},
        $args->{response_data},
    );
}

sub _send_payment_receipt {
    my ( $self, $args ) = @_;
    
    # This would integrate with Koha's notice system
    # For now, this is a placeholder for custom email functionality
    # The standard Koha ACCOUNT_PAYMENT notice will be triggered automatically
    
    return 1;
}

sub _error_page {
    my ( $self, $error_message ) = @_;
    
    my $template = $self->get_template({ file => 'error.tt' });
    $template->param( error_message => $error_message );
    
    return $self->output_html( $template->output() );
}

## OPAC JavaScript injection for payment button
sub opac_js {
    my ($self) = @_;

    return q{
        <script>
        $(document).ready(function() {
            if ($('#finestable').length) {
                var rzpButton = '<div class="btn-group">' +
                    '<a href="/api/v1/contrib/razorpay/pay" class="btn btn-primary btn-sm">' +
                    '<i class="fa fa-credit-card"></i> Pay with RazorPay</a>' +
                    '</div>';
                $('#finestable').before(rzpButton);
            }
        });
        </script>
    };
}

1;
