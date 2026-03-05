#!/bin/bash

set -e

echo "=========================================="
echo "AWS ECS Fargate Deployment"
echo "=========================================="
echo ""

# Check if terraform.tfvars exists
if [ ! -f "../terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values"
    exit 1
fi

cd ../

echo "Step 1: Initialize Terraform..."
terraform init

echo ""
echo "Step 2: Validate Terraform configuration..."
terraform validate

echo ""
echo "Step 3: Plan infrastructure..."
terraform plan -out=tfplan

echo ""
read -p "Do you want to apply this plan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "Step 4: Creating infrastructure..."
terraform apply tfplan

echo ""
echo "Step 5: Building and pushing Docker images..."
cd scripts
./build-and-push.sh

echo ""
echo "Step 6: Updating ECS services..."
cd ../
terraform apply -auto-approve

echo ""
echo "Waiting for services to stabilize (this may take a few minutes)..."
sleep 60

echo ""
echo "Step 7: Initializing databases..."
cd scripts
./init-databases.sh

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "Access your services at:"
cd ../
terraform output alb_url
echo ""
echo "To run tests:"
echo "  ALB_URL=\$(terraform output -raw alb_url)"
echo "  cd ../tests"
echo "  python concurrent_booking_test.py --url http://\$ALB_URL:5002/api"
