# Koha RazorPay Payment Plugin

A production-ready Koha ILS OPAC payment plugin for RazorPay payment gateway, designed specifically for Indian libraries. This plugin enables patrons to pay library fines and fees online using RazorPay's Standard Checkout modal integration.

## Features

### Payment Features
- ✅ **Standard Checkout Modal** - Seamless in-page payment experience
- ✅ **Multiple Payment Methods** - Credit/Debit Cards, UPI, Net Banking, Wallets
- ✅ **One-time Payments** - Pay for specific fines and fees
- ✅ **Partial Payments** - Configurable minimum payment amounts
- ✅ **Real-time Payment Verification** - Signature verification for security
- ✅ **Automatic Reconciliation** - Webhook support for instant payment updates
- ✅ **Transaction Logging** - Complete audit trail in database

### Configuration Options
- 🔧 **Test/Live Mode Toggle** - Easy switching between environments
- 🔧 **Payment Limits** - Configurable min/max transaction amounts
- 🔧 **Partial Payment Rules** - Percentage or fixed amount options
- 🔧 **Branding** - Custom business name, logo, and theme colors
- 🔧 **GST Compliance** - Optional GST reporting and GSTIN
- 🔧 **Institutional Reporting** - Additional fields for compliance

### Admin Features
- 📊 **Transaction Reports** - DataTables-powered admin interface
- 📊 **Advanced Filtering** - Filter by date, status, patron
- 📊 **Export Options** - CSV, Excel, PDF exports
- 📊 **Transaction Details** - Complete payment history
- 📊 **Error Logging** - Comprehensive error tracking

### Security & Compliance
- 🔒 **PCI DSS Compliant** - Handled by RazorPay
- 🔒 **SHA-256 Signature Verification** - All payments verified
- 🔒 **SSL/TLS Required** - Secure payment transmission
- 🔒 **INR Currency Only** - Fixed to Indian Rupees

## Requirements

- **Koha Version**: 24.05 or higher
- **RazorPay Account**: Active account with API credentials
- **PHP/Perl Modules**: 
  - `LWP::UserAgent`
  - `JSON`
  - `Digest::SHA`
  - `MIME::Base64`
  - `Try::Tiny`
- **SSL Certificate**: Required for production (HTTPS)
- **Database**: MySQL/MariaDB (included with Koha)

## Installation

### 1. Download the Plugin

Download the latest `.kpz` file from the [Releases](https://github.com/yourusername/koha-plugin-razorpay/releases) page.

### 2. Enable Koha Plugin System

Edit your `koha-conf.xml` file:

```xml
<enable_plugins>1</enable_plugins>
```

Ensure the `<pluginsdir>` path exists and is writable:

```xml
<pluginsdir>/var/lib/koha/sitename/plugins</pluginsdir>
```

### 3. Enable UseKohaPlugins System Preference

1. Go to **Administration > System Preferences**
2. Search for **UseKohaPlugins**
3. Set to **Enable**

### 4. Upload Plugin

1. Go to **Administration > Manage plugins**
2. Click **Upload plugin**
3. Select the downloaded `.kpz` file
4. Click **Upload**

The plugin will automatically:
- Create the `rzp_transactions` table
- Create the `rzp_error_logs` table
- Set up necessary database indexes

## Configuration

### 1. Access Plugin Configuration

1. Go to **Administration > Manage plugins**
2. Find **RazorPay OPAC Payment Plugin**
3. Click **Actions > Configure**

### 2. General Settings

- **Enable OPAC Payments**: Toggle to enable/disable the plugin
- **Test Mode**: Use this for testing with test credentials

### 3. RazorPay Credentials

#### Test Mode Credentials

1. Log into your [RazorPay Dashboard](https://dashboard.razorpay.com/)
2. Switch to **Test Mode** (toggle in top-left)
3. Go to **Settings > API Keys**
4. Click **Generate Test Keys**
5. Copy **Key ID** and **Key Secret**
6. Enter in plugin configuration:
   - **Test Key ID**: `rzp_test_xxxxxxxxxxxxx`
   - **Test Key Secret**: Your secret key

#### Live Mode Credentials

1. Switch to **Live Mode** in RazorPay Dashboard
2. Complete KYC verification (required for live mode)
3. Generate Live API Keys
4. Enter in plugin configuration:
   - **Live Key ID**: `rzp_live_xxxxxxxxxxxxx`
   - **Live Key Secret**: Your secret key

### 4. Payment Settings

- **Minimum Payment Amount**: Default ₹1.00 (recommended minimum)
- **Maximum Payment Amount**: Leave empty for no limit
- **Enable Partial Payments**: Allow patrons to pay partially
  - **Partial Payment Type**: Percentage or Fixed Amount
  - **Partial Payment Value**: Minimum amount/percentage required

### 5. Branding Settings

- **Business Name**: Your library name (shown on payment modal)
- **Business Logo URL**: Full URL to your library logo
- **Theme Color**: Hex color code (e.g., #528FF0)

### 6. GST & Compliance (Optional)

- **Enable GST Reporting**: For GST-compliant receipts
- **GSTIN Number**: Your library's GSTIN
- **Enable Institutional Reporting**: Additional compliance fields

### 7. Webhook Configuration (Recommended)

Webhooks enable automatic payment verification without manual intervention.

1. In RazorPay Dashboard, go to **Settings > Webhooks**
2. Click **+ Create Webhook**
3. Enter Webhook URL:
   ```
   https://your-koha-opac.org/api/v1/contrib/razorpay/webhook
   ```
4. Select events:
   - `payment.authorized`
   - `payment.failed`
   - `payment.captured`
5. Generate and copy the **Webhook Secret**
6. Enter in plugin configuration:
   - **Test/Live Webhook Secret**: Your webhook secret

## Usage

### For Patrons (OPAC)

1. Patron logs into OPAC
2. Goes to **My Account > Fines**
3. Clicks **Pay with RazorPay** button
4. Reviews payment summary
5. Clicks **Pay Securely with RazorPay**
6. RazorPay modal opens (no redirect)
7. Patron selects payment method and completes payment
8. Modal closes, patron is returned to account page
9. Payment is automatically recorded in Koha

### For Librarians (Staff Interface)

#### View Transactions

1. Go to **Administration > Manage plugins**
2. Click **Actions > Run tool** for RazorPay plugin
3. View transaction report with:
   - Total paid amount
   - Successful/failed transaction counts
   - Detailed transaction list
   - Filter by date, status, patron

#### Export Reports

- Click **Export to CSV** for spreadsheet export
- Click **Print Report** for PDF printing
- Use DataTables export buttons for Excel/PDF

#### View Transaction Details

- Click **View** on any transaction
- See complete payment details:
  - RazorPay Payment ID
  - Payment method used
  - API request/response logs
  - Error messages (if failed)

#### Handle Failed Payments

1. Filter transactions by **Status: Failed**
2. Review error messages in transaction details
3. Contact patron to resolve issues
4. Patron can retry payment from OPAC

## Database Schema

### rzp_transactions Table

```sql
CREATE TABLE rzp_transactions (
    transaction_id INT(11) PRIMARY KEY AUTO_INCREMENT,
    borrowernumber INT(11) NOT NULL,
    amount_paid DECIMAL(28,6) NOT NULL,
    razorpay_order_id VARCHAR(100),
    razorpay_payment_id VARCHAR(100),
    razorpay_signature VARCHAR(255),
    status ENUM('created','attempted','paid','failed','refunded','cancelled'),
    payment_method VARCHAR(50),
    accountlines_ids TEXT,
    api_request TEXT,
    api_response TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_borrowernumber (borrowernumber),
    INDEX idx_razorpay_order_id (razorpay_order_id),
    INDEX idx_razorpay_payment_id (razorpay_payment_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);
```

### rzp_error_logs Table

```sql
CREATE TABLE rzp_error_logs (
    log_id INT(11) PRIMARY KEY AUTO_INCREMENT,
    transaction_id INT(11),
    error_type ENUM('api_error','webhook_error','validation_error','system_error'),
    error_code VARCHAR(50),
    error_message TEXT NOT NULL,
    request_data TEXT,
    response_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_error_type (error_type),
    INDEX idx_created_at (created_at)
);
```

## Testing

### Test Mode Testing

1. Enable **Test Mode** in plugin configuration
2. Use RazorPay test credentials
3. Use test card numbers (no real charges):
   - **Card**: 4111 1111 1111 1111
   - **CVV**: Any 3 digits
   - **Expiry**: Any future date
4. Verify:
   - ✅ Payment modal opens correctly
   - ✅ Payment completes successfully
   - ✅ Transaction recorded in Koha
   - ✅ Patron's fine balance reduced
   - ✅ Transaction appears in admin report

### Production Testing

Before going live:
- ✅ SSL certificate installed and working
- ✅ Webhooks configured and tested
- ✅ Test payments in test mode work perfectly
- ✅ Live API credentials added to plugin
- ✅ Test Mode disabled in plugin configuration
- ✅ Make a small live test payment (₹1 or ₹10)
- ✅ Verify payment appears in RazorPay Dashboard
- ✅ Verify payment recorded correctly in Koha

## Troubleshooting

### Common Issues

#### 1. Payment Modal Doesn't Open

**Cause**: JavaScript not loading or blocked by browser

**Solution**:
- Check browser console for errors
- Ensure `https://checkout.razorpay.com/v1/checkout.js` is accessible
- Check firewall/proxy settings
- Try different browser

#### 2. Payment Verification Failed

**Cause**: Invalid signature or incorrect credentials

**Solution**:
- Verify Key ID and Key Secret are correct
- Ensure no extra spaces in credentials
- Check if using test credentials in live mode (or vice versa)
- Review error logs in `rzp_error_logs` table

#### 3. Webhook Not Working

**Cause**: Webhook URL not accessible or secret mismatch

**Solution**:
- Verify webhook URL is publicly accessible
- Ensure SSL certificate is valid
- Check webhook secret matches plugin configuration
- Test webhook from RazorPay Dashboard

#### 4. Transaction Not Recording in Koha

**Cause**: Database permissions or accountlines issue

**Solution**:
- Check database permissions for plugin tables
- Verify accountlines exist and are outstanding
- Review `rzp_error_logs` table for specific errors
- Enable debug logging in Koha

### Error Logs

Check error logs in database:

```sql
SELECT * FROM rzp_error_logs 
ORDER BY created_at DESC 
LIMIT 20;
```

### Support

For issues specific to:
- **Plugin**: Open issue on [GitHub](https://github.com/yourusername/koha-plugin-razorpay/issues)
- **RazorPay**: Contact [RazorPay Support](https://razorpay.com/support/)
- **Koha**: Visit [Koha Community](https://koha-community.org/)

## Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/yourusername/koha-plugin-razorpay.git
cd koha-plugin-razorpay

# Install dependencies
npm install

# Build plugin
npm run build

# Output: dist/koha-plugin-razorpay-v1.0.0.kpz
```

### Project Structure

```
koha-plugin-razorpay/
├── Koha/
│   └── Plugin/
│       └── Com/
│           └── L2C2/
│               ├── RazorPay.pm              # Main plugin file
│               └── RazorPay/
│                   ├── configure.tt          # Configuration template
│                   ├── opac_online_payment_begin.tt  # Payment page
│                   ├── opac_online_payment_end.tt    # Success/failure page
│                   ├── report.tt            # Admin transaction report
│                   └── error.tt             # Error page
├── package.json                             # NPM configuration
├── gulpfile.js                              # Build script
├── README.md                                # This file
└── LICENSE                                  # GPL-3.0 License
```

## Security Considerations

1. **Always use HTTPS** - Never accept payments over HTTP
2. **Protect API Secrets** - Never commit secrets to version control
3. **Verify Signatures** - Always verify payment signatures
4. **Use Webhooks** - Enable webhooks for additional security
5. **Regular Updates** - Keep Koha and plugin updated
6. **Monitor Logs** - Regularly check error logs
7. **Test Thoroughly** - Test all payment scenarios before going live

## Compliance & Regulations

This plugin helps libraries comply with:
- **Payment Card Industry Data Security Standard (PCI DSS)**
- **RBI (Reserve Bank of India) Guidelines**
- **IT Act 2000 (India)**
- **GST (Goods and Services Tax) Requirements**

**Note**: RazorPay handles all sensitive payment data, ensuring PCI DSS compliance. Your Koha server never processes or stores card details.

## License

This plugin is licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) file for details.

## Credits

**Developed by**: L2C2 Technologies  
**For**: Koha Library Software Community  
**Payment Gateway**: RazorPay

## Changelog

### Version 1.0.0 (2025-10-24)
- Initial release
- Standard Checkout modal integration
- Test/Live mode support
- Partial payments
- Admin transaction reports
- GST compliance features
- Comprehensive error logging
- Webhook support
- PDF receipt generation

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Acknowledgments

- Koha Community for the excellent ILS platform
- RazorPay for providing robust payment infrastructure
- ByWater Solutions for plugin architecture inspiration
- All contributors and testers

---

**For questions or support**: Open an issue on [GitHub](https://github.com/yourusername/koha-plugin-razorpay/issues)

**RazorPay Documentation**: https://razorpay.com/docs/

**Koha Plugin Documentation**: https://wiki.koha-community.org/wiki/Koha_plugins
