#!/bin/bash
# export_outputs.sh - Script to export Terraform outputs to JSON for web UI

echo "🔄 Exporting Terraform outputs to JSON..."

# Create outputs directory if it doesn't exist
mkdir -p web_ui

# Export all Terraform outputs to JSON file
terraform output -json > web_ui/terraform_outputs.json

if [ $? -eq 0 ]; then
    echo "✅ Successfully exported Terraform outputs to web_ui/terraform_outputs.json"
    echo ""
    echo "📊 To view the web dashboard:"
    echo "1. Open the dashboard.html file in your browser"
    echo "2. Click 'Load Terraform Output JSON' and select web_ui/terraform_outputs.json"
    echo "   OR"
    echo "3. Start a simple web server:"
    echo "   cd web_ui && python3 -m http.server 8080"
    echo "   Then open http://localhost:8080/dashboard.html"
else
    echo "❌ Failed to export Terraform outputs"
    echo "Make sure you have run 'terraform apply' successfully"
    exit 1
fi