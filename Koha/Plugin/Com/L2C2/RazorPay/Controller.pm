package Koha::Plugin::Com::L2C2::RazorPay::Controller;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';
use C4::Context;
use JSON qw( decode_json encode_json );
use Digest::SHA qw( hmac_sha256_hex );

=head1 NAME

Koha::Plugin::Com::L2C2::RazorPay::Controller - REST API controller for RazorPay plugin

=cut

sub redirect_to_payment {
    my $c = shift->openapi->valid_input or return;

    # Get the logged in patron from Koha session
    my $user = $c->stash('koha.user');
    
    unless ($user) {
        return $c->render(
            status => 401,
            openapi => {
                error => 'Authentication required',
                error_code => 'AUTH_REQUIRED'
            }
        );
    }

    my $borrowernumber = $user->borrowernumber;
    
    # Redirect to the standard Koha payment page with plugin parameter
    my $url = "/cgi-bin/koha/opac-account-pay.pl?payment_method=Koha::Plugin::Com::L2C2::RazorPay";
    
    return $c->redirect_to($url);
}

sub get_transaction {
    my $c = shift->openapi->valid_input or return;

    my $transaction_id = $c->validation->param('transaction_id');
    
    # Get transaction from database
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(q{
        SELECT * FROM rzp_transactions WHERE transaction_id = ?
    });
    $sth->execute($transaction_id);
    
    my $transaction = $sth->fetchrow_hashref;
    
    unless ($transaction) {
        return $c->render(
            status => 404,
            openapi => {
                error => 'Transaction not found'
            }
        );
    }
    
    # Check if user has permission to view this transaction
    my $user = $c->stash('koha.user');
    if ($user && $user->borrowernumber != $transaction->{borrowernumber}) {
        return $c->render(
            status => 403,
            openapi => {
                error => 'Access denied'
            }
        );
    }
    
    return $c->render(
        status => 200,
        openapi => $transaction
    );
}

sub webhook_handler {
    my $c = shift->openapi->valid_input or return;

    my $payload = $c->req->json;
    
    unless ($payload) {
        return $c->render(
            status => 400,
            openapi => {
                success => 0,
                error => 'Invalid webhook payload'
            }
        );
    }
    
    # Verify webhook signature
    my $signature = $c->req->headers->header('X-Razorpay-Signature');
    
    # Get plugin instance to access configuration
    my $plugin = Koha::Plugin::Com::L2C2::RazorPay->new();
    my $test_mode = $plugin->retrieve_data('test_mode') || 0;
    my $webhook_secret = $test_mode 
        ? $plugin->retrieve_data('test_webhook_secret')
        : $plugin->retrieve_data('live_webhook_secret');
    
    if ($webhook_secret && $signature) {
        my $payload_string = encode_json($payload);
        my $expected_signature = hmac_sha256_hex($payload_string, $webhook_secret);
        
        unless ($signature eq $expected_signature) {
            return $c->render(
                status => 400,
                openapi => {
                    success => 0,
                    error => 'Invalid webhook signature'
                }
            );
        }
    }
    
    # Process webhook event
    my $event = $payload->{event};
    my $payment_entity = $payload->{payload}{payment}{entity};
    
    if ($event eq 'payment.captured' || $event eq 'payment.authorized') {
        # Payment successful - update transaction
        my $order_id = $payment_entity->{order_id};
        my $payment_id = $payment_entity->{id};
        
        my $dbh = C4::Context->dbh;
        my $sth = $dbh->prepare(q{
            UPDATE rzp_transactions 
            SET razorpay_payment_id = ?,
                status = 'paid',
                payment_method = ?,
                api_response = ?
            WHERE razorpay_order_id = ?
        });
        
        $sth->execute(
            $payment_id,
            $payment_entity->{method},
            encode_json($payment_entity),
            $order_id
        );
    }
    
    return $c->render(
        status => 200,
        openapi => {
            success => 1,
            message => 'Webhook processed successfully'
        }
    );
}

1;
