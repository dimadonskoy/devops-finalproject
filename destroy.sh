#!/bin/bash
# destroy.sh - Destroy AWS resources using Terraform

set -e  # exit on error

# Path to your Terraform code
TERRAFORM_DIR="terraform/aws"

echo "🔹 Changing directory to $TERRAFORM_DIR"
cd "$TERRAFORM_DIR" || exit 1

echo "🔹 Initializing Terraform..."
terraform init

echo "🔹 Destroying all AWS resources..."
terraform destroy -auto-approve

echo "✅ AWS infrastructure destroyed"
