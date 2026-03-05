@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Initializing Databases
echo ==========================================
echo.

REM Get cluster and service names from Terraform
cd ..
for /f "tokens=*" %%i in ('terraform output -raw ecs_cluster_name 2^>nul') do set CLUSTER_NAME=%%i
for /f "tokens=*" %%i in ('terraform output -raw inventory_service_name 2^>nul') do set INVENTORY_SERVICE=%%i
for /f "tokens=*" %%i in ('terraform output -raw booking_service_name 2^>nul') do set BOOKING_SERVICE=%%i

if "%CLUSTER_NAME%"=="" (
    echo Error: Could not get ECS cluster name from Terraform outputs
    exit /b 1
)

echo ECS Cluster: %CLUSTER_NAME%
echo Inventory Service: %INVENTORY_SERVICE%
echo Booking Service: %BOOKING_SERVICE%
echo.

REM Get a running task ARN for inventory service
echo Finding running Inventory service task...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --service-name %INVENTORY_SERVICE% --desired-status RUNNING --query "taskArns[0]" --output text') do set INVENTORY_TASK=%%i

if "%INVENTORY_TASK%"=="None" (
    echo Error: No running tasks found for Inventory service
    echo Make sure the service is running and healthy
    exit /b 1
)

echo Found task: %INVENTORY_TASK%
echo.

REM Initialize inventory database
echo Initializing Inventory database...
aws ecs execute-command --cluster %CLUSTER_NAME% --task %INVENTORY_TASK% --container inventory --interactive --command "python init_db.py"

echo.
echo Inventory database initialized
echo.

REM Get a running task ARN for booking service
echo Finding running Booking service task...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --service-name %BOOKING_SERVICE% --desired-status RUNNING --query "taskArns[0]" --output text') do set BOOKING_TASK=%%i

if "%BOOKING_TASK%"=="None" (
    echo Error: No running tasks found for Booking service
    exit /b 1
)

echo Found task: %BOOKING_TASK%
echo.

REM Initialize booking database
echo Initializing Booking database...
aws ecs execute-command --cluster %CLUSTER_NAME% --task %BOOKING_TASK% --container booking --interactive --command "python init_db.py"

echo.
echo ==========================================
echo Databases initialized successfully
echo ==========================================
echo.
echo You can now access the services at:
terraform output alb_url
