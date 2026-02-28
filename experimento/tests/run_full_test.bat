@echo off
setlocal enabledelayedexpansion

echo ========================================
echo CONCURRENT BOOKING EXPERIMENT - FULL TEST
echo ========================================
echo.

if "%BOOKING_URL%"=="" set BOOKING_URL=http://localhost:5002/api
if "%NUM_USERS%"=="" set NUM_USERS=50
if "%ROOM_ID%"=="" set ROOM_ID=1

REM Get current date in YYYY-MM-DD format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set YEAR=%datetime:~0,4%
set MONTH=%datetime:~4,2%
set DAY=%datetime:~6,2%

REM Calculate tomorrow's date (simplified - just add 1 day)
set /a NEXT_DAY=%DAY%+1
if %NEXT_DAY% LSS 10 set NEXT_DAY=0%NEXT_DAY%

REM Calculate day after tomorrow
set /a NEXT_DAY2=%DAY%+3
if %NEXT_DAY2% LSS 10 set NEXT_DAY2=0%NEXT_DAY2%

if "%CHECK_IN%"=="" set CHECK_IN=%YEAR%-03-01
if "%CHECK_OUT%"=="" set CHECK_OUT=%YEAR%-03-03

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
