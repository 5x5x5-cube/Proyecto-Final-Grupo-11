@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Building and Pushing Docker Images to ECR
echo ==========================================
echo.

REM Get AWS account ID and region
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
if "%AWS_REGION%"=="" set AWS_REGION=us-east-1

echo AWS Account ID: %AWS_ACCOUNT_ID%
echo AWS Region: %AWS_REGION%
echo.

REM Get ECR repository URLs from Terraform outputs
cd ..
for /f "tokens=*" %%i in ('terraform output -raw ecr_inventory_repository_url 2^>nul') do set INVENTORY_REPO=%%i
for /f "tokens=*" %%i in ('terraform output -raw ecr_booking_repository_url 2^>nul') do set BOOKING_REPO=%%i

if "%INVENTORY_REPO%"=="" (
    echo Error: Could not get ECR repository URLs from Terraform outputs
    echo Make sure you have run 'terraform apply' first
    exit /b 1
)

echo Inventory Repository: %INVENTORY_REPO%
echo Booking Repository: %BOOKING_REPO%
echo.

REM Login to ECR
echo Logging in to ECR...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

REM Build and push Inventory service
echo.
echo Building Inventory service...
cd ..\inventory
docker build -t inventory-service:latest .
docker tag inventory-service:latest %INVENTORY_REPO%:latest
echo Pushing Inventory service to ECR...
docker push %INVENTORY_REPO%:latest

REM Build and push Booking service
echo.
echo Building Booking service...
cd ..\booking
docker build -t booking-service:latest .
docker tag booking-service:latest %BOOKING_REPO%:latest
echo Pushing Booking service to ECR...
docker push %BOOKING_REPO%:latest

echo.
echo ==========================================
echo Images successfully pushed to ECR
echo ==========================================
echo.
echo Next steps:
echo 1. Update ECS services to use new images:
echo    cd terraform
echo    terraform apply
echo.
echo 2. Initialize databases:
echo    cd scripts
echo    init-databases.bat
