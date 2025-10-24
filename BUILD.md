# RazorPay Plugin - Complete File Structure & Build Guide

## Complete File Structure

```
koha-plugin-razorpay/
│
├── Koha/
│   └── Plugin/
│       └── Com/
│           └── L2C2/
│               ├── RazorPay.pm                              # Main plugin class (2000+ lines)
│               └── RazorPay/
│                   ├── configure.tt                         # Admin configuration template
│                   ├── opac_online_payment_begin.tt         # OPAC payment initiation page
│                   ├── opac_online_payment_end.tt           # Payment success/failure page
│                   ├── report.tt                            # Admin transaction report
│                   ├── error.tt                             # Error display template
│                   └── openapi.json                         # API route definitions
│
├── package.json                                             # NPM package configuration
├── gulpfile.js                                              # Build automation script
├── .gitignore                                               # Git ignore rules
│
├── README.md                                                # Main documentation
├── INSTALL.md                                               # Installation guide
├── CHANGELOG.md                                             # Version history
│
└── (Generated during build)
    ├── build/                                               # Temporary build directory
    │   └── Koha/                                            # Processed plugin files
    └── dist/                                                # Final distribution
        └── koha-plugin-razorpay-v1.0.0.kpz                 # Installable plugin file
```

## File Descriptions

### Core Plugin Files

#### RazorPay.pm (Main Plugin)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay.pm`
**Purpose**: Main plugin logic
**Features**:
- Plugin metadata and configuration
- Payment processing logic
- RazorPay API integration
- Order creation and verification
- Payment signature validation
- Koha account integration
- Transaction database management
- Error logging
- Webhook handling
- Helper methods

#### configure.tt (Configuration Template)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay/configure.tt`
**Purpose**: Admin configuration interface
**Features**:
- Test/Live mode toggle
- API credentials input (Test & Live)
- Payment settings (min/max amounts)
- Partial payment configuration
- Branding customization
- Email settings
- GST compliance options
- Webhook configuration instructions

#### opac_online_payment_begin.tt (Payment Page)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay/opac_online_payment_begin.tt`
**Purpose**: OPAC payment initiation
**Features**:
- Payment summary display
- Charge itemization
- RazorPay Checkout.js integration
- Modal payment form
- Test mode banner
- Security badges
- Payment button with modal trigger
- JavaScript handlers for payment success/failure

#### opac_online_payment_end.tt (Result Page)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay/opac_online_payment_end.tt`
**Purpose**: Payment result display
**Features**:
- Success/failure messages
- Payment receipt details
- Transaction information
- Print receipt option
- Navigation buttons
- Help information
- Back button prevention (for successful payments)

#### report.tt (Admin Report)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay/report.tt`
**Purpose**: Transaction management interface
**Features**:
- DataTables-powered transaction list
- Filter form (date, status, patron)
- Summary statistics
- Transaction detail modal
- Export functionality (CSV, Excel, PDF)
- Receipt download links
- Real-time AJAX data loading

#### error.tt (Error Page)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay/error.tt`
**Purpose**: Error message display
**Features**:
- User-friendly error messages
- Help information
- Action buttons (retry, back to account)
- Troubleshooting tips

#### openapi.json (API Routes)
**Location**: `Koha/Plugin/Com/L2C2/RazorPay/openapi.json`
**Purpose**: API endpoint definitions
**Features**:
- Webhook endpoint specification
- Transaction retrieval endpoint
- Payment initiation endpoint
- Request/response schemas
- Authentication requirements

### Build & Configuration Files

#### package.json
**Purpose**: NPM package definition
**Contents**:
- Plugin metadata
- Build scripts
- Dependencies (gulp, gulp-zip, etc.)
- Version information

#### gulpfile.js
**Purpose**: Automated build process
**Functions**:
- Clean build directories
- Copy plugin files
- Replace version placeholders
- Create .kpz distribution file

#### .gitignore
**Purpose**: Version control exclusions
**Excludes**:
- node_modules
- build/ and dist/ directories
- IDE files
- Temporary files

### Documentation Files

#### README.md
**Comprehensive documentation including**:
- Feature overview
- Requirements
- Installation instructions
- Configuration guide
- Usage instructions
- Testing procedures
- Troubleshooting
- Security considerations
- Development guide

#### INSTALL.md
**Step-by-step installation guide**:
- Prerequisites checklist
- Koha plugin system setup
- Perl module installation
- Plugin upload procedure
- RazorPay account setup
- Plugin configuration
- Webhook setup
- Testing procedures
- Production deployment
- Maintenance tasks

#### CHANGELOG.md
**Version history**:
- Release notes
- New features
- Bug fixes
- Known issues
- Upgrade notes

## Building the Plugin

### Prerequisites

```bash
# Install Node.js (12.x or higher)
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install nodejs npm

# Verify installation
node --version
npm --version
```

### Build Process

```bash
# 1. Clone or download the source code
cd koha-plugin-razorpay/

# 2. Install build dependencies
npm install

# 3. Build the plugin
npm run build

# This will:
# - Clean previous builds
# - Copy all plugin files to build/
# - Replace {VERSION} with actual version
# - Replace date placeholders
# - Create .kpz file in dist/

# Output: dist/koha-plugin-razorpay-v1.0.0.kpz
```

### Manual Build (Without NPM)

```bash
# 1. Create build directory
mkdir -p build/Koha/Plugin/Com/L2C2/

# 2. Copy plugin files
cp -r Koha/Plugin/Com/L2C2/RazorPay* build/Koha/Plugin/Com/L2C2/

# 3. Replace version placeholder
find build -name "*.pm" -type f -exec sed -i 's/{VERSION}/1.0.0/g' {} \;

# 4. Replace date placeholder
find build -name "*.pm" -type f -exec sed -i "s/1970-01-01/$(date +%Y-%m-%d)/g" {} \;

# 5. Create zip file
cd build
zip -r ../koha-plugin-razorpay-v1.0.0.kpz Koha/
cd ..

# 6. Move to dist directory
mkdir -p dist
mv koha-plugin-razorpay-v1.0.0.kpz dist/
```

## Installation from Source

### Option 1: Build and Upload

```bash
# 1. Build the plugin
npm run build

# 2. Upload via Koha web interface
# - Go to Administration > Manage plugins
# - Click "Upload plugin"
# - Select dist/koha-plugin-razorpay-v1.0.0.kpz
# - Click "Upload"
```

### Option 2: Direct Copy (Development)

```bash
# Copy directly to Koha plugins directory
sudo cp -r Koha /var/lib/koha/[instancename]/plugins/

# Fix version placeholders
sudo find /var/lib/koha/[instancename]/plugins -name "*.pm" -type f -exec sed -i 's/{VERSION}/1.0.0/g' {} \;
sudo find /var/lib/koha/[instancename]/plugins -name "*.pm" -type f -exec sed -i "s/1970-01-01/$(date +%Y-%m-%d)/g" {} \;

# Set correct permissions
sudo chown -R [koha-user]:[koha-group] /var/lib/koha/[instancename]/plugins/
sudo chmod -R 755 /var/lib/koha/[instancename]/plugins/

# Restart Koha
sudo koha-plack --restart [instancename]
```

## Testing Checklist

### Pre-Installation Tests
- [ ] Koha version 24.05 or higher
- [ ] Plugin system enabled
- [ ] Required Perl modules installed
- [ ] SSL certificate installed (for production)
- [ ] RazorPay account created

### Post-Installation Tests
- [ ] Plugin appears in plugin list
- [ ] Configuration page loads
- [ ] Database tables created (`rzp_transactions`, `rzp_error_logs`)
- [ ] Configuration saves successfully

### Functional Tests
- [ ] Payment button appears on OPAC fines page
- [ ] Payment modal opens correctly
- [ ] Test payment completes successfully
- [ ] Transaction recorded in Koha
- [ ] Fine balance reduced correctly
- [ ] Admin report displays transaction
- [ ] Transaction details accessible
- [ ] Export functions work
- [ ] Error handling works (test with failed card)
- [ ] Webhook receives events (if configured)

### Production Readiness
- [ ] All test mode tests pass
- [ ] Live credentials configured
- [ ] Test mode disabled
- [ ] Live webhook configured
- [ ] Small live payment tested and verified
- [ ] Staff trained on transaction reports
- [ ] Patron communication prepared
- [ ] Monitoring plan in place

## Deployment Recommendations

### Development Environment
- Use Test Mode
- Use test API keys
- Test all payment scenarios
- Test error handling
- Test webhook functionality
- Review all templates

### Staging Environment
- Use Test Mode initially
- Full integration testing
- Load testing (if high volume expected)
- User acceptance testing
- Staff training
- Switch to Live Mode for final testing

### Production Environment
- Use Live Mode only
- Monitor first transactions closely
- Have rollback plan ready
- Keep backups current
- Monitor error logs daily (first week)
- Gradual patron adoption

## Version Control Best Practices

### What to Commit
- Source code (Koha/ directory)
- Build files (package.json, gulpfile.js)
- Documentation (*.md files)
- Configuration examples

### What NOT to Commit
- API keys and secrets
- Build artifacts (build/, dist/)
- node_modules/
- IDE-specific files
- Temporary files
- Production configuration

### Gitignore Template
Already provided in `.gitignore` file.

## Maintenance & Updates

### Regular Maintenance
**Weekly**:
```sql
-- Check for errors
SELECT * FROM rzp_error_logs WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Check transaction volume
SELECT status, COUNT(*) as count, SUM(amount_paid) as total 
FROM rzp_transactions 
WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY status;
```

**Monthly**:
- Backup transaction tables
- Review and archive old transactions (if needed)
- Check for plugin updates
- Review RazorPay settlement reports
- Reconcile transactions

### Updating the Plugin

```bash
# 1. Backup current installation
mysqldump -u root -p koha_[instance] rzp_transactions rzp_error_logs > backup_$(date +%Y%m%d).sql

# 2. Download new version

# 3. Upload via Koha interface
# Plugin will run upgrade() method automatically

# 4. Test functionality

# 5. Monitor for issues
```

## Support & Resources

- **GitHub Repository**: https://github.com/yourusername/koha-plugin-razorpay
- **Issue Tracker**: https://github.com/yourusername/koha-plugin-razorpay/issues
- **RazorPay Docs**: https://razorpay.com/docs/
- **Koha Community**: https://koha-community.org/
- **Koha Wiki**: https://wiki.koha-community.org/wiki/Koha_plugins

## License

GNU General Public License v3.0

## Credits

Developed by L2C2 Technologies for the Koha Community.

---

**Last Updated**: 2025-10-24  
**Plugin Version**: 1.0.0  
**Minimum Koha Version**: 24.05
