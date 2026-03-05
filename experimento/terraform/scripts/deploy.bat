@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo AWS ECS Fargate Deployment
echo ==========================================
echo.

REM Check if terraform.tfvars exists
if not exist "..\terraform.tfvars" (
    echo Error: terraform.tfvars not found
    echo Please copy terraform.tfvars.example to terraform.tfvars and fill in your values
    exit /b 1
)

cd ..

echo Step 1: Initialize Terraform...
terraform init

echo.
echo Step 2: Validate Terraform configuration...
terraform validate

echo.
echo Step 3: Plan infrastructure...
terraform plan -out=tfplan

echo.
set /p CONFIRM="Do you want to apply this plan? (yes/no): "

if not "%CONFIRM%"=="yes" (
    echo Deployment cancelled
    exit /b 0
)

echo.
echo Step 4: Creating infrastructure...
terraform apply tfplan

echo.
echo Step 5: Building and pushing Docker images...
cd scripts
call build-and-push.bat

echo.
echo Step 6: Updating ECS services...
cd ..
terraform apply -auto-approve

echo.
echo Waiting for services to stabilize (this may take a few minutes)...
timeout /t 60 /nobreak

echo.
echo Step 7: Initializing databases...
cd scripts
call init-databases.bat

echo.
echo ==========================================
echo Deployment Complete!
echo ==========================================
echo.
echo Access your services at:
cd ..
terraform output alb_url
echo.
echo To run tests:
echo   $env:ALB_URL = terraform output -raw alb_url
echo   cd ..\tests
echo   python concurrent_booking_test.py --url http://$env:ALB_URL:5002/api
