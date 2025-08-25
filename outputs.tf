# outputs.tf
output "admin_summary" {
  description = "Summary of all managed administrators"
  value = {
    total_admins = length(local.admins_map)
    admins_by_org = {
      for org_id in toset([for admin in local.admins_raw : admin.organization_id]) : org_id => [
        for email, admin in local.admins_map : admin if admin.organization_id == org_id
      ]
    }
  }
}

output "admin_security_report" {
  description = "Security status report for all administrators"
  value = {
    for email, report in local.admin_report : email => {
      email              = report.email
      organization_id    = report.organization_id
      permission_level   = report.permission_level
      two_factor_enabled = report.two_factor_enabled
      has_api_key        = report.api_key_exists
      last_api_usage     = report.last_api_usage
      risk_status        = report.is_risk ? "HIGH RISK" : "OK"
    }
  }
  sensitive = true
}

output "risky_admins_alert" {
  description = "List of administrators flagged as potential security risks"
  value = {
    count = length(local.risky_admins)
    message = length(local.risky_admins) == 0 ? "No risky administrators identified" : "Security risks detected"
    details = {
      for email, admin in local.risky_admins : email => {
        email = admin.email
        organization_id = admin.organization_id
        reasons = compact([
          admin.two_factor_enabled == false ? "2FA not enabled" : "",
          admin.api_key_exists == true && admin.last_api_usage == "never" ? "Has API key but never used APIs" : "",
          admin.api_key_exists == true && local.admin_timestamp_checks[email].is_valid_timestamp && local.admin_timestamp_checks[email].is_inactive ? "Inactive API usage (>${var.api_inactivity_threshold_days} days)" : ""
        ])
      }
    }
  }
}

output "two_factor_compliance" {
  description = "Two-factor authentication compliance report"
  value = {
    enabled_count = length([
      for email, report in local.admin_report : report 
      if report.two_factor_enabled == true
    ])
    disabled_count = length([
      for email, report in local.admin_report : report 
      if report.two_factor_enabled == false
    ])
    unknown_count = length([
      for email, report in local.admin_report : report 
      if report.two_factor_enabled == "unknown"
    ])
    compliance_rate = format("%.1f%%", 
      length([for email, report in local.admin_report : report if report.two_factor_enabled == true]) / 
      length(local.admin_report) * 100
    )
  }
}

output "api_usage_summary" {
  description = "API usage summary for all administrators"
  value = {
    active_users = length([
      for email, report in local.admin_report : report 
      if local.admin_timestamp_checks[email].is_valid_timestamp && 
         !local.admin_timestamp_checks[email].is_inactive
    ])
    inactive_users = length([
      for email, report in local.admin_report : report 
      if report.last_api_usage == "never" || 
         report.last_api_usage == "unknown" ||
         (local.admin_timestamp_checks[email].is_valid_timestamp && local.admin_timestamp_checks[email].is_inactive)
    ])
    never_used = length([
      for email, report in local.admin_report : report 
      if report.last_api_usage == "never"
    ])
    unknown_status = length([
      for email, report in local.admin_report : report 
      if report.last_api_usage == "unknown"
    ])
  }
}