#!/bin/bash
# destroy.sh - Manually destroy Terraform AWS infrastructure

set -e

WORKDIR="terraform/aws"

echo "🔹 Initializing Terraform..."
terraform -chdir="$WORKDIR" init

echo "🔹 Destroying AWS resources..."
terraform -chdir="$WORKDIR" destroy -auto-approve

echo "✅ Terraform destroy complete"
