#!/bin/bash

set -e

echo "=========================================="
echo "Initializing Databases"
echo "=========================================="
echo ""

# Get cluster and service names from Terraform
cd ../
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
INVENTORY_SERVICE=$(terraform output -raw inventory_service_name 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ]; then
    echo "Error: Could not get ECS cluster name from Terraform outputs"
    exit 1
fi

echo "ECS Cluster: $CLUSTER_NAME"
echo "Inventory Service: $INVENTORY_SERVICE"
echo ""

# Get a running task ARN for inventory service
echo "Finding running Inventory service task..."
INVENTORY_TASK=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $INVENTORY_SERVICE --desired-status RUNNING --query 'taskArns[0]' --output text)

if [ "$INVENTORY_TASK" == "None" ] || [ -z "$INVENTORY_TASK" ]; then
    echo "Error: No running tasks found for Inventory service"
    echo "Make sure the service is running and healthy"
    exit 1
fi

echo "Found task: $INVENTORY_TASK"
echo ""

# Initialize inventory database
echo "Initializing Inventory database..."
aws ecs execute-command \
    --cluster $CLUSTER_NAME \
    --task $INVENTORY_TASK \
    --container inventory \
    --interactive \
    --command "python init_db.py"

echo ""
echo "✓ Inventory database initialized"
echo ""

# Get a running task ARN for booking service
echo "Finding running Booking service task..."
BOOKING_SERVICE=$(terraform output -raw booking_service_name 2>/dev/null || echo "")
BOOKING_TASK=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $BOOKING_SERVICE --desired-status RUNNING --query 'taskArns[0]' --output text)

if [ "$BOOKING_TASK" == "None" ] || [ -z "$BOOKING_TASK" ]; then
    echo "Error: No running tasks found for Booking service"
    exit 1
fi

echo "Found task: $BOOKING_TASK"
echo ""

# Initialize booking database
echo "Initializing Booking database..."
aws ecs execute-command \
    --cluster $CLUSTER_NAME \
    --task $BOOKING_TASK \
    --container booking \
    --interactive \
    --command "python init_db.py"

echo ""
echo "=========================================="
echo "✓ Databases initialized successfully"
echo "=========================================="
echo ""
echo "You can now access the services at:"
terraform output alb_url
