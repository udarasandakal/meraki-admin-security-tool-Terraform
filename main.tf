# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    meraki = {
      source  = "CiscoDevNet/meraki"
      version = ">= 0.1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0.0"
    }
  }
}

# Provider configuration
provider "meraki" {
  api_key = var.meraki_api_key != null ? var.meraki_api_key : null
  # If api_key is null, provider will use MERAKI_API_KEY environment variable
}

# Read admin data from CSV file
locals {
  admins_csv_content = file(var.admins_csv_file)
  admins_raw = csvdecode(local.admins_csv_content)
  
  # Transform CSV data into a map for easier processing
  admins_map = {
    for admin in local.admins_raw : admin.email => {
      email           = admin.email
      permission_level = admin.permission_level
      organization_id = admin.organization_id
    }
  }
  
  # Calculate risk threshold timestamp
  risk_threshold = timeadd(timestamp(), "-${var.api_inactivity_threshold_days * 24}h")
  
  # Get unique organization IDs
  organization_ids = toset([for admin in local.admins_raw : admin.organization_id])
}

# Data source to get organization information
data "meraki_organizations" "all" {}

# Data source to get existing organization admins
data "meraki_organization_admins" "current" {
  for_each = local.organization_ids
  
  organization_id = each.key
  
  depends_on = [data.meraki_organizations.all]
}

# Create/Update organization administrators
resource "meraki_organization_admin" "admins" {
  for_each = local.admins_map

  organization_id = each.value.organization_id
  email          = each.value.email
  name           = split("@", each.value.email)[0] # Use email prefix as name
  org_access     = each.value.permission_level == "full" ? "full" : "read-only"

  lifecycle {
    create_before_destroy = true
  }
}

# Data source to get API requests overview for each organization
# Note: This data source might not be available in CiscoDevNet provider
# We'll rely on the Python script for API usage information
# data "meraki_organization_api_requests_overview" "usage" {
#   for_each = local.organization_ids
#   
#   organization_id = each.key
#   timespan       = var.api_inactivity_threshold_days * 24 * 3600 # Convert days to seconds
#   
#   depends_on = [meraki_organization_admin.admins]
# }

# External data source to check 2FA status
data "external" "admin_2fa_status" {
  for_each = local.admins_map
  
  program = ["python3", "${path.module}/scripts/check_2fa_status.py"]
  
  query = {
    api_key     = var.meraki_api_key != null ? var.meraki_api_key : ""
    admin_email = each.value.email
    org_id      = each.value.organization_id
  }

  depends_on = [meraki_organization_admin.admins]
}

# Local calculations for risk assessment and reporting
locals {
  # Helper function to safely compare timestamps
  admin_timestamp_checks = {
    for email, admin in local.admins_map : email => {
      last_active = try(data.external.admin_2fa_status[email].result.last_active, "never")
      is_valid_timestamp = try(
        regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", data.external.admin_2fa_status[email].result.last_active) != null,
        false
      )
      is_inactive = try(
        regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}", data.external.admin_2fa_status[email].result.last_active) != null ? 
        timecmp(data.external.admin_2fa_status[email].result.last_active, local.risk_threshold) < 0 : 
        false,
        false
      )
    }
  }

  # Combine all admin information for reporting
  admin_report = {
    for email, admin in local.admins_map : email => {
      email           = admin.email
      organization_id = admin.organization_id
      permission_level = admin.permission_level
      two_factor_enabled = try(
        tobool(data.external.admin_2fa_status[email].result.two_factor_enabled), 
        null
      )
      last_api_usage = try(
        data.external.admin_2fa_status[email].result.last_active,
        "unknown"
      )
      api_key_exists = try(
        tobool(data.external.admin_2fa_status[email].result.has_api_key),
        false
      )
      is_risk = (
        # Risk if 2FA is not enabled
        try(tobool(data.external.admin_2fa_status[email].result.two_factor_enabled), true) == false ||
        (
          # Risk if has API key but inactive
          try(tobool(data.external.admin_2fa_status[email].result.has_api_key), false) == true &&
          (
            # Never used APIs or unknown status
            local.admin_timestamp_checks[email].last_active == "never" ||
            local.admin_timestamp_checks[email].last_active == "unknown" ||
            # Has valid timestamp but is inactive
            (local.admin_timestamp_checks[email].is_valid_timestamp && local.admin_timestamp_checks[email].is_inactive)
          )
        )
      )
    }
  }
  
  # Filter risky admins for alerts
  risky_admins = {
    for email, report in local.admin_report : email => report if report.is_risk
  }
}