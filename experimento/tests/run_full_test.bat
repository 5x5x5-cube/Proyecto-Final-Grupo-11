@echo off
setlocal enabledelayedexpansion

echo ========================================
echo CONCURRENT BOOKING EXPERIMENT - FULL TEST
echo ========================================
echo.

if "%BOOKING_URL%"=="" set BOOKING_URL=http://localhost:5002/api
if "%NUM_USERS%"=="" set NUM_USERS=50
if "%ROOM_ID%"=="" set ROOM_ID=1

for /f "tokens=1-3 delims=/ " %%a in ('date /t') do (
    set TODAY=%%c-%%a-%%b
)

if "%CHECK_IN%"=="" set CHECK_IN=%TODAY%
if "%CHECK_OUT%"=="" set CHECK_OUT=%TODAY%

echo Configuration:
echo   Booking Service: %BOOKING_URL%
echo   Concurrent Users: %NUM_USERS%
echo   Room ID: %ROOM_ID%
echo   Check-in Date: %CHECK_IN%
echo   Check-out Date: %CHECK_OUT%
echo.

echo Step 1: Running concurrent booking test...
python concurrent_booking_test.py --url "%BOOKING_URL%" --users %NUM_USERS% --room-id %ROOM_ID% --check-in "%CHECK_IN%" --check-out "%CHECK_OUT%" --output "test_results.json"

set TEST_EXIT_CODE=%ERRORLEVEL%

echo.
echo Step 2: Validating database consistency...
python validation\validate_results.py --room-id %ROOM_ID% --check-in "%CHECK_IN%"

set VALIDATION_EXIT_CODE=%ERRORLEVEL%

echo.
echo ========================================
echo TEST SUMMARY
echo ========================================
echo.

if %TEST_EXIT_CODE%==0 if %VALIDATION_EXIT_CODE%==0 (
    echo [32m✓ ALL TESTS PASSED[0m
    exit /b 0
) else (
    echo [31m✗ SOME TESTS FAILED[0m
    if %TEST_EXIT_CODE%==0 (
        echo   Concurrent Test: PASS
    ) else (
        echo   Concurrent Test: FAIL
    )
    if %VALIDATION_EXIT_CODE%==0 (
        echo   DB Validation: PASS
    ) else (
        echo   DB Validation: FAIL
    )
    exit /b 1
)
