# Cisco Meraki Administrator Security Management Tool

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-7C3AED?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.6+-3776AB?style=flat-square&logo=python)](https://www.python.org/)
[![Meraki](https://img.shields.io/badge/Cisco-Meraki-1BA0D7?style=flat-square&logo=cisco)](https://meraki.cisco.com/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

A comprehensive Infrastructure as Code solution for managing Cisco Meraki dashboard administrators with automated security monitoring and compliance reporting.

<img width="3174" height="2236" alt="Cisco Meraki - Administrator Security Dashboard" src="https://github.com/user-attachments/assets/20db9f95-d07b-4fb1-9cbe-837952316301" />

## 🚀 Features

<table>
<tr>
<td width="50%">

### 🏗️ Infrastructure as Code
- **Terraform-based** administrator management
- **Declarative configuration** with version control
- **Idempotent operations** - safe to run multiple times
- **Bulk operations** - manage hundreds of administrators

</td>
<td width="50%">

### 🔒 Security Monitoring
- **2FA compliance** tracking and reporting
- **API usage monitoring** and risk assessment
- **Inactive administrator** detection
- **Automated security alerts** and notifications

</td>
</tr>
<tr>
<td>

### 📊 Professional Dashboard
- **UI** responsive web interface
- **Real-time security** status visualization
- **Compliance reporting** with exportable data
- **Risk assessment** with detailed recommendations

</td>
<td>

### 📝 Easy Management
- **CSV-based configuration** - no complex syntax
- **Automated workflows** with CI/CD integration
- **Comprehensive logging** and error handling
- **Multi-organization support** for MSPs

</td>
</tr>
</table>

## 📋 Architecture Overview

Simple workflow: **CSV Data** → **Terraform** → **Meraki API** → **Security Analysis** → **Web Dashboard**

## 🛠️ Prerequisites

Before you begin, ensure you have:

- **Terraform** >= 1.0 installed ([Download](https://www.terraform.io/downloads))
- **Python** 3.6+ with pip ([Download](https://www.python.org/downloads/))
- **Meraki Dashboard API Key** with organization admin privileges
- **Basic knowledge** of CSV files and command line

## ⚡ Quick Start

### 1️⃣ Download and Setup

```bash
# Clone or download this repository
git clone https://github.com/yourusername/meraki-admin-security-tool.git
cd meraki-admin-security-tool

# Install Python dependencies
pip install requests

# Initialize Terraform
terraform init
```

### 2️⃣ Configure Your Environment

```bash
# Set your Meraki API key (recommended)
export MERAKI_API_KEY="your_api_key_here"

# OR create terraform.tfvars file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your API key
```

### 3️⃣ Define Your Administrators

Edit `admins.csv` with your administrator details:

```csv
email,permission_level,organization_id
admin@company.com,full,123456
readonly@company.com,read-only,123456
security@company.com,full,654321
analyst@company.com,read-only,654321
```

### 4️⃣ Apply Configuration

```bash
# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### 5️⃣ Generate Security Report

```bash
# Export data for dashboard
./export_outputs.sh

# Start web server (optional)
cd web_ui
python3 -m http.server 8080
# Open http://localhost:8080/dashboard.html
```

## 📊 Dashboard Features

### Security Overview Cards
- **Total Administrators** - Complete count across all organizations
- **High-Risk Administrators** - Immediate attention required
- **2FA Compliance** - Two-factor authentication adoption rate
- **API Usage Status** - Active vs. inactive API users

### Risk Management Section
- **Critical Security Risks** - Administrators requiring immediate attention
- **Detailed Risk Reasons** - Specific security concerns explained
- **Compliance Status** - Visual indicators for quick assessment
- **Actionable Recommendations** - Clear next steps for remediation

### Administrator Overview
- **Complete Administrator List** - All administrators with security details
- **Permission Tracking** - Current access levels and organization assignments
- **Activity Monitoring** - Last API usage and activity timestamps
- **Security Status** - Visual indicators for 2FA, API keys, and risk level

## 🔧 Configuration Options

### Environment Variables
```bash
# Required: Meraki API Key
export MERAKI_API_KEY="your_meraki_api_key"

# Optional: Debug mode
export TF_LOG=DEBUG

# Optional: Custom CSV file location
export TF_VAR_admins_csv_file="custom_admins.csv"
```

### Terraform Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `meraki_api_key` | Meraki Dashboard API Key | `null` | `"abc123..."` |
| `admins_csv_file` | Path to administrators CSV | `"admins.csv"` | `"data/admins.csv"` |
| `api_inactivity_threshold_days` | Days before flagging inactive API usage | `30` | `45` |

### CSV File Format

The administrators CSV file requires these columns:

- **email** *(required)*: Administrator email address
- **permission_level** *(required)*: `full` or `read-only`
- **organization_id** *(required)*: Target Meraki organization ID

**Example CSV Format:**
```csv
email,permission_level,organization_id
john.admin@company.com,full,123456
jane.readonly@company.com,read-only,123456
security.team@company.com,full,654321
```

## 🚨 Security Monitoring

### Automated Risk Assessment

The tool automatically identifies administrators who pose security risks:

#### High-Risk Criteria
- **2FA Not Enabled** - Missing two-factor authentication
- **Dormant API Keys** - Have API access but haven't used it recently
- **Inactive Administrators** - No API activity beyond threshold period
- **Permission Mismatches** - Inappropriate access levels

#### Security Validation Logic
```python
# Example security validation
is_high_risk = (
    not two_factor_enabled or
    (has_api_key and last_usage > 30_days_ago) or
    (has_api_key and never_used_api)
)
```

### Compliance Reporting

- **2FA Adoption Rate** - Percentage of administrators with 2FA enabled
- **API Usage Statistics** - Active vs. inactive API key holders
- **Risk Distribution** - Breakdown of security risk categories
- **Trend Analysis** - Historical compliance data (with regular runs)

## 🔄 Automation and CI/CD

### GitHub Actions Integration

Create `.github/workflows/security-check.yml`:

```yaml
name: Daily Security Check

on:
  schedule:
    - cron: '0 9 * * *'  # Daily at 9 AM
  workflow_dispatch:

jobs:
  security-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
    
    - name: Run Security Assessment
      env:
        MERAKI_API_KEY: ${{ secrets.MERAKI_API_KEY }}
      run: |
        terraform init
        terraform apply -auto-approve
        ./export_outputs.sh
    
    - name: Upload Security Report
      uses: actions/upload-artifact@v3
      with:
        name: security-report
        path: web_ui/terraform_outputs.json
```

### Cron Automation

```bash
# Add to crontab for daily checks
0 9 * * * cd /path/to/project && terraform apply -auto-approve && ./export_outputs.sh
```

**Automated Workflow:** Schedule → Security Scan → Risk Assessment → Report Generation → Notification

## 🛠️ Advanced Usage

### Multiple Organizations

```csv
email,permission_level,organization_id
admin@company.com,full,123456
admin@company.com,read-only,654321
regional@company.com,full,789012
```

### Custom Risk Thresholds

```hcl
# terraform.tfvars
api_inactivity_threshold_days = 45  # Custom threshold
```

### Integration with External Systems

```bash
# Export data for external processing
terraform output -json > security_data.json

# Send to monitoring system
curl -X POST -H "Content-Type: application/json" \
  -d @security_data.json \
  https://your-monitoring-system.com/api/security-reports
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### API Rate Limits
```bash
# Solution: Add delays between operations
export TF_LOG=DEBUG
terraform apply

# Check rate limit status
curl -H "X-Cisco-Meraki-API-Key: $MERAKI_API_KEY" \
  https://api.meraki.com/api/v1/organizations
```

#### Permission Errors
```bash
# Verify API key permissions
terraform output admin_summary

# Check organization access
curl -H "X-Cisco-Meraki-API-Key: $MERAKI_API_KEY" \
  "https://api.meraki.com/api/v1/organizations/YOUR_ORG_ID/admins"
```

#### CSV Format Issues
```bash
# Validate CSV format
python3 -c "import csv; print(list(csv.DictReader(open('admins.csv'))))"
```

### Debug Mode

Enable detailed debug output for troubleshooting:

```bash
export TF_LOG=DEBUG
terraform apply
```

## 📈 Performance and Scale

### Benchmarks

| Metric | Small Org | Medium Org | Large Org |
|--------|-----------|------------|-----------|
| Administrators | 1-10 | 11-100 | 100+ |
| Execution Time | <30s | 1-3 min | 3-10 min |
| Memory Usage | <50MB | 50-200MB | 200MB+ |
| API Calls | 10-20 | 50-150 | 200+ |

### Optimization Tips

```bash
# Parallel execution for large deployments
terraform apply -parallelism=10

# Reduced API calls with caching
export TF_LOG=WARN  # Reduce logging overhead
```

## 🔐 Security Considerations

### API Key Management
- Store API keys as environment variables only
- Never commit API keys to version control
- Use secure credential management in production
- Regularly rotate API keys

### Access Control
- Limit API key permissions to required organizations
- Implement proper file permissions (600) for sensitive files
- Use HTTPS for all API communications
- Enable audit logging for all changes

### Data Protection
```bash
# Secure file permissions
chmod 600 terraform.tfvars
chmod 600 *.tfstate
chmod +x scripts/*.py
```

## 🤝 Contributing

We welcome contributions!

### Development Setup

```bash
# Fork and clone repository
git clone https://github.com/yourusername/meraki-admin-security-tool.git
cd meraki-admin-security-tool

# Install development dependencies
pip install requests pytest

# Run tests
terraform validate
python3 -m pytest tests/ (if tests exist)

# Format code
terraform fmt
```

### Feature Requests

Have an idea? [Create a discussion](../../discussions) or [open an issue](../../issues/new)!

Popular requested features:
- [ ] Slack/Teams notifications
- [ ] PDF report generation  
- [ ] Historical trend analysis
- [ ] Custom security policies
- [ ] SSO integration
- [ ] Multi-tenant dashboard
- [ ] Email alerting system
- [ ] Custom compliance rules

## 📊 Output Examples

### Terraform Outputs

```bash
# View security summary
terraform output admin_security_report

# Check risky administrators
terraform output risky_admins_alert

# View compliance metrics
terraform output two_factor_compliance

# API usage statistics
terraform output api_usage_summary
```

### Example Output Format
```json
{
  "risky_admins_alert": {
    "count": 2,
    "message": "Security risks detected",
    "details": {
      "admin@company.com": {
        "email": "admin@company.com",
        "organization_id": "123456",
        "reasons": ["2FA not enabled", "Has API key but never used APIs"]
      }
    }
  }
}
```

## 📋 File Structure

```
meraki-admin-security-tool/
├── README.md                   # This file
├── LICENSE                     # MIT License
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Variable definitions
├── outputs.tf                  # Output definitions
├── terraform.tfvars.example   # Example variables file
├── admins.csv                  # Administrator definitions
├── export_outputs.sh          # Export script for web UI
├── scripts/
│   └── check_2fa_status.py    # Security monitoring script
├── web_ui/
│   └── dashboard.html         # Professional security dashboard
└── docs/
    ├── INSTALLATION.md        # Detailed installation guide
    └── TROUBLESHOOTING.md     # Common issues and solutions
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License - Feel free to use, modify, and distribute
Commercial use ✅ | Private use ✅ | Modification ✅ | Distribution ✅
```

## 🙏 Acknowledgments

- **Cisco DevNet** for the excellent Meraki Terraform provider
- **HashiCorp** for Terraform and comprehensive documentation

## 📞 Support and Community

| Type | Link | Description |
|------|------|-------------|
| 📖 **Documentation** | [Wiki](../../wiki) | Detailed guides and examples |
| 🐛 **Bug Reports** | [Issues](../../issues) | Report bugs and request features |
| 💬 **Discussions** | [Discussions](../../discussions) | Ask questions and share ideas |
| 📧 **Contact** | [Email](mailto:udarasandakal@gmail.com) | Direct support contact |

---

**⭐ If this tool helps you manage Meraki administrators more securely, please star the repository!**

**Made with ❤️ for the Cisco community**

- By Udara Thenuwara
