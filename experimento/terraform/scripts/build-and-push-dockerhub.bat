@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Building and Pushing Docker Images to Docker Hub
echo ==========================================
echo.

REM Check if Docker Hub username is provided
if "%1"=="" (
    echo Error: Docker Hub username required
    echo Usage: build-and-push-dockerhub.bat YOUR_DOCKERHUB_USERNAME
    exit /b 1
)

set DOCKER_USERNAME=%1

echo Docker Hub Username: %DOCKER_USERNAME%
echo.

REM Login to Docker Hub
echo Please login to Docker Hub:
docker login

if errorlevel 1 (
    echo Error: Docker Hub login failed
    exit /b 1
)

REM Build and push Inventory service
echo.
echo Building Inventory service...
cd ..\..\inventory
docker build -t %DOCKER_USERNAME%/inventory-service:latest .
if errorlevel 1 (
    echo Error: Failed to build inventory service
    exit /b 1
)

echo Pushing Inventory service to Docker Hub...
docker push %DOCKER_USERNAME%/inventory-service:latest
if errorlevel 1 (
    echo Error: Failed to push inventory service
    exit /b 1
)

REM Build and push Booking service
echo.
echo Building Booking service...
cd ..\booking
docker build -t %DOCKER_USERNAME%/booking-service:latest .
if errorlevel 1 (
    echo Error: Failed to build booking service
    exit /b 1
)

echo Pushing Booking service to Docker Hub...
docker push %DOCKER_USERNAME%/booking-service:latest
if errorlevel 1 (
    echo Error: Failed to push booking service
    exit /b 1
)

echo.
echo ==========================================
echo Images successfully pushed to Docker Hub
echo ==========================================
echo.
echo Images:
echo - %DOCKER_USERNAME%/inventory-service:latest
echo - %DOCKER_USERNAME%/booking-service:latest
echo.
echo Next steps:
echo 1. Update terraform.tfvars with:
echo    docker_hub_username = "%DOCKER_USERNAME%"
echo.
echo 2. Deploy infrastructure:
echo    cd ..\terraform
echo    terraform apply
