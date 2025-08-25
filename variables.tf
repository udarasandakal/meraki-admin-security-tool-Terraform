# variables.tf
variable "meraki_api_key" {
  description = "Meraki Dashboard API Key"
  type        = string
  sensitive   = true
  default     = null # Will use MERAKI_DASHBOARD_API_KEY environment variable if not set
}

variable "admins_csv_file" {
  description = "Path to the CSV file containing admin information"
  type        = string
  default     = "admins.csv"
  
  validation {
    condition     = can(regex(".*\\.csv$", var.admins_csv_file))
    error_message = "The admins_csv_file must have a .csv extension."
  }
}

variable "api_inactivity_threshold_days" {
  description = "Number of days of API inactivity before flagging as risk"
  type        = number
  default     = 30
  
  validation {
    condition     = var.api_inactivity_threshold_days > 0 && var.api_inactivity_threshold_days <= 365
    error_message = "API inactivity threshold must be between 1 and 365 days."
  }
}