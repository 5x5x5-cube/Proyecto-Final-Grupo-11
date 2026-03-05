#!/bin/bash

set -e

echo "=========================================="
echo "Destroying AWS Infrastructure"
echo "=========================================="
echo ""
echo "WARNING: This will destroy all resources created by Terraform"
echo "This action cannot be undone!"
echo ""

read -p "Are you sure you want to destroy all resources? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Destruction cancelled"
    exit 0
fi

cd ../

echo ""
echo "Destroying infrastructure..."
terraform destroy

echo ""
echo "=========================================="
echo "✓ All resources destroyed"
echo "=========================================="
