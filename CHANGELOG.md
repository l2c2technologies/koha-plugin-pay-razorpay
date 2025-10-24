# Changelog

All notable changes to the Koha RazorPay Payment Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-24

### Added
- Initial release of RazorPay Payment Plugin for Koha
- Standard Checkout modal integration for seamless in-page payments
- Test Mode and Live Mode toggle for easy testing
- Support for multiple payment methods (Cards, UPI, Net Banking, Wallets)
- Partial payment support with configurable minimum amounts
- Payment amount limits (configurable min/max)
- Real-time payment signature verification using SHA-256
- Automatic payment reconciliation via webhooks
- Comprehensive transaction logging in `rzp_transactions` table
- Detailed error logging in `rzp_error_logs` table
- Admin transaction report with DataTables interface
- Advanced filtering by date, status, and patron
- Export functionality (CSV, Excel, PDF)
- Transaction detail view with complete API logs
- Configurable branding (business name, logo, theme color)
- GST compliance features with GSTIN support
- Institutional reporting options
- Custom email receipt configuration (optional)
- PDF receipt generation capability
- Complete webhook support for automated verification
- Security features:
  - SSL/TLS requirement for production
  - Payment signature verification
  - PCI DSS compliance via RazorPay
  - Secure API credential storage
- INR (Indian Rupees) currency support only
- Koha 24.05+ compatibility
- Comprehensive installation documentation
- Detailed configuration guide
- Testing instructions for both test and live modes
- Error handling and troubleshooting guide

### Security
- All payments processed over HTTPS
- SHA-256 signature verification for all transactions
- No credit card data stored in Koha database
- PCI DSS compliance handled by RazorPay
- API credentials stored securely in plugin data

### Documentation
- Complete README.md with features and usage
- Detailed INSTALL.md with step-by-step instructions
- Inline code documentation
- Database schema documentation
- Troubleshooting guide
- Security best practices

### Known Limitations
- Currency fixed to INR (Indian Rupees) only
- Refunds must be processed manually via RazorPay Dashboard
- Requires Koha 24.05 or higher
- SSL certificate required for production use
- Internet connectivity required for payment processing

## [Unreleased]

### Planned for Future Releases
- Multi-currency support (if RazorPay adds support)
- Automated refund processing from Koha staff interface
- Enhanced reporting with charts and graphs
- Payment receipt email templates
- SMS notifications via RazorPay
- Recurring payment support for membership fees
- Subscription payment support
- Split payments across multiple accountlines
- Payment history API for mobile apps
- Integration with Koha's action logs
- Custom payment workflows
- Payment reminders via email/SMS
- Bulk payment processing
- Advanced fraud detection integration
- Payment analytics dashboard

## Version History

### Version Numbering
- **Major version** (x.0.0): Breaking changes, major features
- **Minor version** (1.x.0): New features, backward compatible
- **Patch version** (1.0.x): Bug fixes, minor improvements

### Support Policy
- Latest version: Full support
- Previous major version: Security updates only
- Older versions: No support (upgrade recommended)

### Upgrade Notes

#### Upgrading to 1.0.0
This is the initial release. Fresh installation only.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

---

For the complete version history and detailed changes, visit:
https://github.com/yourusername/koha-plugin-razorpay/releases
