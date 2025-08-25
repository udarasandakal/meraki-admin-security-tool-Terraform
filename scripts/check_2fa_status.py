#!/usr/bin/env python3
# scripts/check_2fa_status.py
"""
Script to check 2FA status and API key usage for Meraki administrators.
This script is called by Terraform's external data source.
"""

import json
import sys
import requests
import argparse
from urllib.parse import urljoin
from datetime import datetime, timedelta

def check_admin_status(api_key, admin_email, org_id):
    """
    Check if an administrator has 2FA enabled and their API usage.
    
    Args:
        api_key (str): Meraki API key
        admin_email (str): Administrator email address
        org_id (str): Organization ID
    
    Returns:
        dict: Result containing 2FA status, API key status, and last usage
    """
    base_url = "https://api.meraki.com/api/v1/"
    headers = {
        "X-Cisco-Meraki-API-Key": api_key,
        "Content-Type": "application/json"
    }
    
    result = {
        "two_factor_enabled": "false",
        "has_api_key": "false",
        "last_active": "never",
        "admin_id": "",
        "error": ""
    }
    
    try:
        # Get organization administrators
        url = urljoin(base_url, f"organizations/{org_id}/admins")
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        admins = response.json()
        
        # Find the specific admin
        admin_info = None
        for admin in admins:
            if admin.get('email', '').lower() == admin_email.lower():
                admin_info = admin
                break
        
        if not admin_info:
            result["error"] = f"Administrator {admin_email} not found in organization {org_id}"
            return result
        
        result["admin_id"] = admin_info.get('id', '')
        
        # Check if 2FA is enabled
        # Different possible field names in the API response
        two_factor_enabled = admin_info.get('twoFactorAuthEnabled', 
                                          admin_info.get('two_factor_auth_enabled',
                                          admin_info.get('hasTwoFactorAuthEnabled', 
                                          admin_info.get('authenticationMethod', '') == 'Two-factor authentication')))
        
        result["two_factor_enabled"] = str(two_factor_enabled).lower()
        
        # Check for API key existence and last usage
        # This information might be in different fields depending on API version
        has_api_key = admin_info.get('hasApiKey', 
                                   admin_info.get('apiAccess', 
                                   admin_info.get('api_access', False)))
        result["has_api_key"] = str(has_api_key).lower()
        
        # Get last active time
        last_active = admin_info.get('lastActive', 
                                   admin_info.get('last_active', 
                                   admin_info.get('lastSeen', '')))
        
        if last_active and last_active != '':
            result["last_active"] = last_active
        else:
            result["last_active"] = "never"
            
        # Try to get more detailed API usage information
        try:
            api_url = urljoin(base_url, f"organizations/{org_id}/apiRequests")
            # Get API requests for the last 30 days
            params = {
                'timespan': 30 * 24 * 3600,  # 30 days in seconds
                'adminId': result["admin_id"]
            }
            api_response = requests.get(api_url, headers=headers, params=params, timeout=30)
            
            if api_response.status_code == 200:
                api_data = api_response.json()
                if api_data and len(api_data) > 0:
                    # Find the most recent API request
                    most_recent = None
                    for request in api_data:
                        if request.get('adminId') == result["admin_id"]:
                            if most_recent is None or request.get('ts', '') > most_recent:
                                most_recent = request.get('ts', '')
                    
                    if most_recent:
                        result["last_active"] = most_recent
                        
        except Exception as api_error:
            # API usage data is optional, don't fail if we can't get it
            pass
        
        return result
        
    except requests.exceptions.RequestException as e:
        result["error"] = f"API request failed: {str(e)}"
        return result
    except json.JSONDecodeError as e:
        result["error"] = f"Failed to parse JSON response: {str(e)}"
        return result
    except Exception as e:
        result["error"] = f"Unexpected error: {str(e)}"
        return result

def main():
    """Main function to handle Terraform external data source call."""
    try:
        # Read input from Terraform
        input_data = json.loads(sys.stdin.read())
        
        api_key = input_data.get('api_key', '')
        admin_email = input_data.get('admin_email', '')
        org_id = input_data.get('org_id', '')
        
        if not all([api_key, admin_email, org_id]):
            result = {
                "two_factor_enabled": "false",
                "has_api_key": "false", 
                "last_active": "never",
                "admin_id": "",
                "error": "Missing required parameters: api_key, admin_email, or org_id"
            }
        else:
            result = check_admin_status(api_key, admin_email, org_id)
        
        # Output result as JSON for Terraform
        print(json.dumps(result))
        
    except Exception as e:
        # Return error result
        error_result = {
            "two_factor_enabled": "false",
            "has_api_key": "false",
            "last_active": "never", 
            "admin_id": "",
            "error": f"Script execution error: {str(e)}"
        }
        print(json.dumps(error_result))
        sys.exit(1)

if __name__ == "__main__":
    main()
