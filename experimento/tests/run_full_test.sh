#!/bin/bash

echo "========================================"
echo "CONCURRENT BOOKING EXPERIMENT - FULL TEST"
echo "========================================"
echo ""

BOOKING_URL="${BOOKING_URL:-http://localhost:5002/api}"
NUM_USERS="${NUM_USERS:-50}"
ROOM_ID="${ROOM_ID:-1}"
CHECK_IN="${CHECK_IN:-$(date -d '+1 day' +%Y-%m-%d)}"
CHECK_OUT="${CHECK_OUT:-$(date -d '+3 days' +%Y-%m-%d)}"

echo "Configuration:"
echo "  Booking Service: $BOOKING_URL"
echo "  Concurrent Users: $NUM_USERS"
echo "  Room ID: $ROOM_ID"
echo "  Check-in Date: $CHECK_IN"
echo "  Check-out Date: $CHECK_OUT"
echo ""

echo "Step 1: Running concurrent booking test..."
python concurrent_booking_test.py \
    --url "$BOOKING_URL" \
    --users "$NUM_USERS" \
    --room-id "$ROOM_ID" \
    --check-in "$CHECK_IN" \
    --check-out "$CHECK_OUT" \
    --output "test_results.json"

TEST_EXIT_CODE=$?

echo ""
echo "Step 2: Validating database consistency..."
python validation/validate_results.py \
    --room-id "$ROOM_ID" \
    --check-in "$CHECK_IN"

VALIDATION_EXIT_CODE=$?

echo ""
echo "========================================"
echo "TEST SUMMARY"
echo "========================================"
echo ""

if [ $TEST_EXIT_CODE -eq 0 ] && [ $VALIDATION_EXIT_CODE -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    echo "  Concurrent Test: $([ $TEST_EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "  DB Validation: $([ $VALIDATION_EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    exit 1
fi
