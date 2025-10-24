# Quick Start Guide - RazorPay Plugin for Koha

Get your library accepting online payments in 30 minutes!

## 🚀 Super Quick Setup (Test Mode)

### Step 1: Prerequisites (5 minutes)

1. **Koha 24.05+** installed and running
2. **RazorPay Account** - Sign up at https://razorpay.com (free)
3. **Test API Keys** from RazorPay Dashboard

```bash
# Quick checks
koha-list # Verify Koha instance
curl -I https://your-opac.org # Verify HTTPS (required)
```

### Step 2: Enable Koha Plugins (2 minutes)

```bash
# Edit koha-conf.xml
sudo nano /etc/koha/sites/[yourlibrary]/koha-conf.xml

# Change this line:
<enable_plugins>0</enable_plugins>
# To:
<enable_plugins>1</enable_plugins>

# Save and restart
sudo koha-plack --restart [yourlibrary]
```

### Step 3: Get RazorPay Test Keys (3 minutes)

1. Go to https://dashboard.razorpay.com/
2. Toggle to **Test Mode** (top-left)
3. Settings → API Keys → **Generate Test Key**
4. Copy:
   - Key ID (starts with `rzp_test_`)
   - Key Secret (click eye icon)

### Step 4: Install Plugin (5 minutes)

**Option A: Pre-built Plugin**
1. Download `koha-plugin-razorpay-v1.0.0.kpz` from releases
2. Koha → Administration → Manage plugins
3. Upload plugin → Select file → Upload

**Option B: Build from Source**
```bash
cd koha-plugin-razorpay
npm install
npm run build
# Upload dist/koha-plugin-razorpay-v1.0.0.kpz
```

### Step 5: Configure Plugin (10 minutes)

1. Administration → Manage plugins
2. RazorPay Plugin → **Configure**
3. **General Settings**:
   - Enable OPAC Payments: **Enabled**
   - Test Mode: **Test Mode**
4. **Test Credentials**:
   - Test Key ID: `rzp_test_xxxxx`
   - Test Key Secret: `[your-secret]`
5. **Payment Settings**:
   - Minimum Amount: `1.00`
   - Maximum Amount: (leave empty)
6. **Branding**:
   - Business Name: Your Library Name
   - Theme Color: `#528FF0`
7. **Save Configuration**

### Step 6: Test Payment (5 minutes)

1. **Create Test Fine**:
   - Staff interface → Patron → Accounting → Create manual invoice
   - Amount: ₹100

2. **Make Test Payment**:
   - OPAC → Login as patron
   - My Account → Fines
   - Click **Pay with RazorPay**
   - Use test card: `4111 1111 1111 1111`
   - CVV: `123`, Expiry: `12/25`
   - Complete payment

3. **Verify**:
   - ✅ Payment successful
   - ✅ Fine reduced to ₹0
   - ✅ Transaction in admin report

**🎉 You're now accepting test payments!**

---

## 📋 Going Live (Production)

### Before Going Live Checklist

- [ ] Test mode payments work perfectly
- [ ] Generated Live API keys from RazorPay
- [ ] KYC completed in RazorPay account
- [ ] SSL certificate valid (HTTPS working)
- [ ] Staff trained on viewing transactions
- [ ] Backup of database taken

### Go Live Steps

1. **Get Live Keys**:
   - RazorPay Dashboard → Switch to **Live Mode**
   - Settings → API Keys → Generate Key
   - Copy Key ID and Secret

2. **Update Plugin**:
   - Plugin Configuration → **Live Mode Credentials**
   - Live Key ID: `rzp_live_xxxxx`
   - Live Key Secret: `[your-secret]`
   - **Test Mode**: Switch to **Live Mode**
   - Save

3. **Test Small Payment**:
   - Make real ₹10 payment
   - Verify in RazorPay Dashboard (Live)
   - Verify in Koha transaction report

4. **Monitor**:
   - Check transactions daily (first week)
   - Review error logs
   - Respond to patron queries quickly

---

## 🎯 Key Features at a Glance

### For Patrons
- 💳 Pay fines online 24/7
- 📱 Mobile-friendly payment modal
- 🔒 Secure (no redirect, stays on OPAC)
- 💵 Multiple payment methods (UPI, Cards, Wallets)
- 📄 Instant receipt

### For Librarians
- 📊 Real-time transaction reports
- 🔍 Advanced filtering and search
- 📥 Export to Excel/CSV/PDF
- 🔔 Automatic fine reduction
- 📝 Complete audit trail

### For IT Admins
- 🧪 Test mode for safe testing
- 🔄 Webhook support
- 🗄️ Complete transaction logging
- 🔐 Secure credential storage
- 📈 Easy to monitor

---

## 🆘 Quick Troubleshooting

### Payment Modal Doesn't Open
```bash
# Check browser console for errors
# Verify these URLs are accessible:
curl https://checkout.razorpay.com/v1/checkout.js
```

### "Configuration Not Found" Error
- Verify plugin is installed
- Check enable_plugins=1 in koha-conf.xml
- Restart Koha: `sudo koha-plack --restart [instance]`

### Payment Successful but Fine Not Reduced
```sql
-- Check transaction was recorded
SELECT * FROM rzp_transactions 
WHERE borrowernumber = [patron_id] 
ORDER BY created_at DESC LIMIT 1;

-- Check for errors
SELECT * FROM rzp_error_logs 
ORDER BY created_at DESC LIMIT 5;
```

### Webhook Not Working
1. Verify webhook URL is publicly accessible
2. Check webhook secret matches plugin config
3. Test from RazorPay Dashboard → Webhooks → Send Test

---

## 📚 Documentation

- **Full Documentation**: [README.md](README.md)
- **Installation Guide**: [INSTALL.md](INSTALL.md)
- **Build Instructions**: [BUILD.md](BUILD.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

---

## 🔧 Common Configurations

### Configuration 1: Basic (Recommended for Start)
```
✓ Test Mode: Enabled
✓ Min Amount: ₹1
✓ Max Amount: No limit
✓ Partial Payments: Disabled
✓ GST: Disabled
```

### Configuration 2: With Partial Payments
```
✓ Test Mode: Enabled
✓ Min Amount: ₹1
✓ Max Amount: No limit
✓ Partial Payments: Enabled
✓ Partial Type: Percentage
✓ Partial Value: 25%
```

### Configuration 3: Production with GST
```
✓ Test Mode: Disabled (Live)
✓ Min Amount: ₹10
✓ Max Amount: ₹50,000
✓ Partial Payments: Enabled (50%)
✓ GST: Enabled
✓ GSTIN: [Your GSTIN]
```

---

## 💰 Payment Methods Supported

RazorPay automatically displays available payment methods:

- **Credit/Debit Cards** (Visa, Mastercard, RuPay, Amex)
- **UPI** (Google Pay, PhonePe, Paytm, BHIM)
- **Net Banking** (All major banks)
- **Wallets** (Paytm, Mobikwik, Freecharge, Airtel Money)
- **EMI** (if enabled in RazorPay)

---

## 🔐 Security Notes

- ✅ All payment data handled by RazorPay (PCI DSS compliant)
- ✅ No credit card data stored in Koha
- ✅ SHA-256 signature verification
- ✅ HTTPS required for production
- ✅ API keys stored securely

---

## 📞 Support

### Plugin Issues
- GitHub: https://github.com/yourusername/koha-plugin-razorpay/issues
- Email: support@l2c2.in

### RazorPay Issues
- Support: https://razorpay.com/support/
- Docs: https://razorpay.com/docs/

### Koha Issues
- Community: https://koha-community.org/
- IRC: #koha on irc.oftc.net

---

## 🎓 Training Resources

### For Patrons
Create a simple guide:
```
How to Pay Library Fines Online
1. Log into library catalog
2. Click "My Account"
3. Click "Fines"
4. Click "Pay with RazorPay"
5. Complete payment
6. Done! Your fine is paid.
```

### For Staff
- View transactions: Administration → Manage plugins → RazorPay → Run tool
- Filter by date/status/patron
- Export reports for accounting
- Check error logs if payment issues

---

## 🚦 Status Monitoring

### Daily (First Week)
```sql
-- Today's transactions
SELECT status, COUNT(*), SUM(amount_paid) 
FROM rzp_transactions 
WHERE DATE(created_at) = CURDATE()
GROUP BY status;
```

### Weekly
```sql
-- Last 7 days summary
SELECT DATE(created_at) as date, 
       COUNT(*) as transactions,
       SUM(amount_paid) as total
FROM rzp_transactions 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
AND status = 'paid'
GROUP BY DATE(created_at);
```

---

## ✨ Success Metrics

After 1 month, you should see:
- 📈 Reduction in manual payment processing
- 💸 Faster fine collection
- 😊 Improved patron satisfaction
- ⏰ 24/7 payment availability
- 📊 Better financial reporting

---

**Ready to accept payments?** Just follow the 6 steps above!

**Need help?** Check the full [Installation Guide](INSTALL.md)

**Questions?** Open an issue on [GitHub](https://github.com/yourusername/koha-plugin-razorpay/issues)

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-24  
**License**: GPL-3.0  
**Developed by**: L2C2 Technologies
