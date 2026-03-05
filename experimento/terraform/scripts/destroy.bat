@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Destroying AWS Infrastructure
echo ==========================================
echo.
echo WARNING: This will destroy all resources created by Terraform
echo This action cannot be undone!
echo.

set /p CONFIRM="Are you sure you want to destroy all resources? (yes/no): "

if not "%CONFIRM%"=="yes" (
    echo Destruction cancelled
    exit /b 0
)

cd ..

echo.
echo Destroying infrastructure...
terraform destroy

echo.
echo ==========================================
echo All resources destroyed
echo ==========================================
