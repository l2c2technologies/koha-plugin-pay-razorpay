# RazorPay Payment Plugin - Installation Guide

Complete step-by-step installation guide for Koha RazorPay Payment Plugin.

## Prerequisites Checklist

Before installation, ensure you have:

- [ ] Koha 24.05 or higher installed
- [ ] Root/sudo access to Koha server
- [ ] Active RazorPay account with KYC completed
- [ ] RazorPay API credentials (Key ID & Secret)
- [ ] SSL certificate installed on OPAC (HTTPS)
- [ ] Database backup of your Koha installation

## Step 1: Prepare Koha Plugin System

### 1.1 Edit koha-conf.xml

```bash
sudo nano /etc/koha/sites/[yourlibrary]/koha-conf.xml
```

Find and change:
```xml
<enable_plugins>0</enable_plugins>
```

To:
```xml
<enable_plugins>1</enable_plugins>
```

### 1.2 Verify Plugin Directory

Check that the plugins directory exists and is writable:

```bash
# Check if directory exists
ls -la /var/lib/koha/[yourlibrary]/plugins

# If it doesn't exist, create it
sudo mkdir -p /var/lib/koha/[yourlibrary]/plugins

# Set correct permissions
sudo chown -R [koha-instance]:[koha-instance] /var/lib/koha/[yourlibrary]/plugins
sudo chmod 755 /var/lib/koha/[yourlibrary]/plugins
```

### 1.3 Restart Koha Services

```bash
sudo koha-plack --restart [yourlibrary]
sudo service apache2 restart
```

## Step 2: Enable Plugins in Koha

### 2.1 Access Staff Interface

1. Log into Koha staff interface
2. Go to **More > Administration**

### 2.2 Enable UseKohaPlugins

1. In Administration, click **Global system preferences**
2. Search for: `UseKohaPlugins`
3. Set value to: **Enable**
4. Click **Save all**

## Step 3: Install Required Perl Modules

### 3.1 Check Installed Modules

```bash
perl -MLWP::UserAgent -e 'print "LWP::UserAgent OK\n"'
perl -MJSON -e 'print "JSON OK\n"'
perl -MDigest::SHA -e 'print "Digest::SHA OK\n"'
perl -MMIME::Base64 -e 'print "MIME::Base64 OK\n"'
perl -MTry::Tiny -e 'print "Try::Tiny OK\n"'
```

### 3.2 Install Missing Modules

If any module is missing, install it:

```bash
# For Debian/Ubuntu
sudo apt-get install libwww-perl libjson-perl libdigest-sha-perl libmime-base64-perl libtry-tiny-perl

# Or using CPAN
sudo cpan LWP::UserAgent JSON Digest::SHA MIME::Base64 Try::Tiny
```

## Step 4: Download and Install Plugin

### 4.1 Download Plugin

Download the latest `.kpz` file from:
- GitHub Releases: `https://github.com/yourusername/koha-plugin-razorpay/releases`
- Or build from source (see README.md)

### 4.2 Upload Plugin via Web Interface

1. Go to **More > Administration > Manage plugins**
2. Click **Upload plugin** button
3. Choose the downloaded `.kpz` file
4. Click **Upload**
5. Wait for success message

### 4.3 Verify Installation

After upload, you should see:
- "RazorPay OPAC Payment Plugin" in the plugins list
- Status: Installed
- Actions available: Configure, Run tool, Uninstall

### 4.4 Verify Database Tables

Check that plugin tables were created:

```bash
mysql -u root -p

USE koha_[yourlibrary];

SHOW TABLES LIKE 'rzp_%';
-- Should show: rzp_transactions, rzp_error_logs

DESCRIBE rzp_transactions;
DESCRIBE rzp_error_logs;

EXIT;
```

## Step 5: Configure RazorPay Account

### 5.1 Create RazorPay Account

If you don't have one:
1. Go to https://razorpay.com/
2. Click **Sign Up**
3. Complete registration
4. Complete KYC verification (required for live payments)

### 5.2 Generate Test API Keys

1. Log into RazorPay Dashboard: https://dashboard.razorpay.com/
2. Click **Test Mode** toggle (top-left)
3. Go to **Settings** (gear icon) > **API Keys**
4. Click **Generate Test Key**
5. Copy and securely save:
   - Key ID (starts with `rzp_test_`)
   - Key Secret (click eye icon to reveal)

### 5.3 Generate Live API Keys (For Production)

**Only after testing is complete:**

1. Switch to **Live Mode** in RazorPay Dashboard
2. Ensure KYC is completed
3. Go to **Settings > API Keys**
4. Click **Generate Key**
5. Copy and securely save:
   - Key ID (starts with `rzp_live_`)
   - Key Secret

⚠️ **Important**: Never commit these keys to version control!

## Step 6: Configure Plugin

### 6.1 Access Plugin Configuration

1. Go to **More > Administration > Manage plugins**
2. Find "RazorPay OPAC Payment Plugin"
3. Click **Actions > Configure**

### 6.2 General Settings

- **Enable OPAC Payments**: Select **Enabled**
- **Test Mode**: Select **Test Mode** (for now)

### 6.3 Enter Test Credentials

- **Test Key ID**: Enter your `rzp_test_xxxxx`
- **Test Key Secret**: Enter your test secret key
- **Test Webhook Secret**: Leave empty for now (we'll configure webhooks later)

### 6.4 Configure Payment Settings

**Minimum Payment Amount**: `1.00` (recommended)
**Maximum Payment Amount**: Leave empty (no limit) or set library policy
**Enable Partial Payments**: Choose based on library policy
- If enabled:
  - **Partial Payment Type**: Percentage or Amount
  - **Partial Payment Value**: e.g., 25% or ₹100

### 6.5 Configure Branding

- **Business Name**: Your library's name (e.g., "City Public Library")
- **Business Logo URL**: Full URL to logo (e.g., `https://yourlibrary.org/logo.png`)
- **Theme Color**: Hex color (e.g., `#528FF0` for blue)

### 6.6 Email & Notifications

- **Send Custom Receipt Email**: Disabled (Koha's ACCOUNT_PAYMENT notice will be sent)
- **Receipt Email From**: Leave as default

### 6.7 GST & Compliance (Optional)

If your library is GST-registered:
- **Enable GST Reporting**: Enabled
- **GSTIN Number**: Enter your GSTIN

### 6.8 Save Configuration

Click **Save Configuration**

## Step 7: Configure Webhooks (Recommended)

Webhooks enable automatic payment verification.

### 7.1 Get Webhook URL

Your webhook URL will be:
```
https://your-koha-opac.org/api/v1/contrib/razorpay/webhook
```

Replace `your-koha-opac.org` with your actual OPAC domain.

### 7.2 Configure in RazorPay Dashboard

1. Go to RazorPay Dashboard
2. Ensure you're in **Test Mode**
3. Go to **Settings > Webhooks**
4. Click **+ Create New Webhook**
5. Enter details:
   - **Webhook URL**: Your webhook URL (from above)
   - **Secret**: Click **Generate** (copy this secret!)
   - **Active Events**: Select:
     - ☑ payment.authorized
     - ☑ payment.captured
     - ☑ payment.failed
6. Click **Create Webhook**

### 7.3 Add Webhook Secret to Plugin

1. Go back to plugin configuration
2. **Test Webhook Secret**: Paste the secret you copied
3. Click **Save Configuration**

### 7.4 Test Webhook

RazorPay Dashboard > Webhooks > Click your webhook > Click **Send Test Webhook**

Check Koha logs to verify webhook was received.

## Step 8: Testing

### 8.1 Test Payment Flow

1. **Create Test Patron with Fines**:
   ```bash
   # In Koha staff interface
   - Create or find a patron
   - Add a manual invoice/fine
   ```

2. **Test OPAC Payment**:
   - Log into OPAC as the patron
   - Go to **My Account > Fines**
   - Click **Pay with RazorPay** button
   - Verify payment modal opens
   - Use test card: `4111 1111 1111 1111`
   - CVV: Any 3 digits
   - Expiry: Any future date
   - Complete payment

3. **Verify Results**:
   - Payment should succeed
   - Modal should close
   - Patron redirected to success page
   - Fine balance should be reduced
   - Transaction should appear in admin report

### 8.2 Check Transaction in Admin

1. Go to **Administration > Manage plugins**
2. RazorPay plugin > **Actions > Run tool**
3. Verify transaction appears in report
4. Check transaction details
5. Verify payment recorded in patron's account

### 8.3 Test Failed Payment

1. Use RazorPay test card for failure: `4000 0000 0000 0002`
2. Verify error handling:
   - Error message displayed
   - Transaction logged as failed
   - Fine balance unchanged
   - Error logged in `rzp_error_logs` table

## Step 9: Go Live (Production)

**Only proceed after thorough testing!**

### 9.1 Switch to Live Mode

1. Generate Live API keys in RazorPay (if not done)
2. Configure Live webhook in RazorPay
3. Update plugin configuration:
   - **Test Mode**: Switch to **Live Mode**
   - **Live Key ID**: Enter live key
   - **Live Key Secret**: Enter live secret
   - **Live Webhook Secret**: Enter live webhook secret
4. **Save Configuration**

### 9.2 Final Production Checks

- [ ] SSL certificate valid and working
- [ ] Test Mode disabled
- [ ] Live API keys entered correctly
- [ ] Live webhook configured and tested
- [ ] Staff trained on viewing transactions
- [ ] Patron communication prepared

### 9.3 Make Test Live Payment

1. Create a small test charge (₹10)
2. Complete actual payment with real card/UPI
3. Verify in RazorPay Dashboard (Live Mode)
4. Verify in Koha transaction report
5. Verify patron account updated

### 9.4 Monitor Initial Transactions

For first few days:
- Check transaction report daily
- Monitor error logs
- Respond quickly to patron queries
- Watch for any failed payments

## Step 10: Maintenance

### 10.1 Regular Checks

**Weekly**:
- Review error logs for issues
- Check for failed payments
- Verify webhook is functioning

**Monthly**:
- Review transaction reports
- Reconcile with RazorPay settlement reports
- Check for plugin updates

### 10.2 Backup

Regularly backup:
```bash
# Backup plugin tables
mysqldump -u root -p koha_[yourlibrary] rzp_transactions rzp_error_logs > rzp_backup_$(date +%Y%m%d).sql
```

### 10.3 Updates

When new plugin version available:
1. Backup database
2. Download new `.kpz` file
3. Upload via **Manage plugins**
4. Plugin will automatically run upgrade routine
5. Test all functionality

## Troubleshooting Installation

### Issue: "Plugin upload failed"

**Solution**:
- Check plugin directory permissions
- Verify `enable_plugins` is set to 1
- Check Apache error logs: `sudo tail -f /var/log/apache2/error.log`

### Issue: "Database tables not created"

**Solution**:
```bash
# Check database permissions
mysql -u root -p
GRANT ALL PRIVILEGES ON koha_[yourlibrary].* TO 'koha_[yourlibrary]'@'localhost';
FLUSH PRIVILEGES;
```

### Issue: "Payment modal doesn't open"

**Solution**:
- Check browser console for JavaScript errors
- Verify firewall allows `checkout.razorpay.com`
- Test in incognito/private window
- Try different browser

### Issue: "Webhook not receiving events"

**Solution**:
- Verify webhook URL is publicly accessible
- Test with curl: `curl -I https://your-opac.org/api/v1/contrib/razorpay/webhook`
- Check firewall rules
- Verify SSL certificate is valid

## Getting Help

- **Plugin Issues**: https://github.com/yourusername/koha-plugin-razorpay/issues
- **RazorPay Support**: https://razorpay.com/support/
- **Koha Community**: https://koha-community.org/support/
- **Koha Mailing List**: koha@lists.koha-community.org

## Security Best Practices

1. **Always use HTTPS** - Never accept payments over HTTP
2. **Secure API Keys** - Store securely, never in version control
3. **Regular Updates** - Keep Koha and plugin updated
4. **Monitor Logs** - Check error logs regularly
5. **Limit Access** - Restrict who can view/modify plugin configuration
6. **Backup Regularly** - Backup transaction data
7. **Test Thoroughly** - Test all scenarios before going live

---

**Congratulations!** You have successfully installed the RazorPay Payment Plugin for Koha.

For questions or issues, please refer to the [README.md](README.md) or open an issue on GitHub.
