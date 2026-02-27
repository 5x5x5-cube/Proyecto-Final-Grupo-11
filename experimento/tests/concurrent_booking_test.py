import requests
import threading
import time
from datetime import datetime, timedelta
import json
from collections import defaultdict

class ConcurrentBookingTest:
    def __init__(self, booking_service_url, num_users=50):
        self.booking_service_url = booking_service_url
        self.num_users = num_users
        self.results = []
        self.lock = threading.Lock()
        
    def make_booking_request(self, user_id, room_id, check_in_date, check_out_date):
        start_time = time.time()
        
        try:
            response = requests.post(
                f"{self.booking_service_url}/bookings/confirm",
                json={
                    "user_id": user_id,
                    "room_id": room_id,
                    "check_in_date": check_in_date,
                    "check_out_date": check_out_date
                },
                timeout=10
            )
            
            elapsed_time = time.time() - start_time
            
            result = {
                "user_id": user_id,
                "status_code": response.status_code,
                "response_time": elapsed_time,
                "success": response.status_code == 201,
                "response_data": response.json() if response.headers.get('content-type') == 'application/json' else None,
                "timestamp": datetime.now().isoformat()
            }
            
            with self.lock:
                self.results.append(result)
                
            return result
            
        except requests.exceptions.Timeout:
            elapsed_time = time.time() - start_time
            result = {
                "user_id": user_id,
                "status_code": 0,
                "response_time": elapsed_time,
                "success": False,
                "error": "Timeout",
                "timestamp": datetime.now().isoformat()
            }
            with self.lock:
                self.results.append(result)
            return result
            
        except Exception as e:
            elapsed_time = time.time() - start_time
            result = {
                "user_id": user_id,
                "status_code": 0,
                "response_time": elapsed_time,
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            with self.lock:
                self.results.append(result)
            return result
    
    def run_concurrent_test(self, room_id, check_in_date, check_out_date):
        print(f"\n{'='*80}")
        print(f"CONCURRENT BOOKING TEST")
        print(f"{'='*80}")
        print(f"Room ID: {room_id}")
        print(f"Check-in: {check_in_date}")
        print(f"Check-out: {check_out_date}")
        print(f"Concurrent Users: {self.num_users}")
        print(f"{'='*80}\n")
        
        self.results = []
        threads = []
        
        test_start_time = time.time()
        
        for i in range(self.num_users):
            user_id = 1000 + i
            thread = threading.Thread(
                target=self.make_booking_request,
                args=(user_id, room_id, check_in_date, check_out_date)
            )
            threads.append(thread)
        
        for thread in threads:
            thread.start()
        
        for thread in threads:
            thread.join()
        
        test_elapsed_time = time.time() - test_start_time
        
        self.analyze_results(test_elapsed_time)
        
        return self.results
    
    def analyze_results(self, total_test_time):
        print(f"\n{'='*80}")
        print(f"TEST RESULTS ANALYSIS")
        print(f"{'='*80}\n")
        
        successful_bookings = [r for r in self.results if r['success']]
        failed_bookings = [r for r in self.results if not r['success']]
        
        response_times = [r['response_time'] for r in self.results]
        response_times.sort()
        
        status_codes = defaultdict(int)
        for r in self.results:
            status_codes[r['status_code']] += 1
        
        print(f"Total Requests: {len(self.results)}")
        print(f"Successful Bookings (201): {len(successful_bookings)}")
        print(f"Failed Bookings: {len(failed_bookings)}")
        print(f"\nStatus Code Distribution:")
        for code, count in sorted(status_codes.items()):
            print(f"  {code}: {count} requests")
        
        print(f"\n{'='*80}")
        print(f"PERFORMANCE METRICS")
        print(f"{'='*80}\n")
        
        print(f"Total Test Duration: {total_test_time:.3f}s")
        print(f"\nResponse Time Statistics:")
        print(f"  Min: {min(response_times):.3f}s")
        print(f"  Max: {max(response_times):.3f}s")
        print(f"  Average: {sum(response_times)/len(response_times):.3f}s")
        print(f"  Median: {response_times[len(response_times)//2]:.3f}s")
        
        p95_index = int(len(response_times) * 0.95)
        p99_index = int(len(response_times) * 0.99)
        print(f"  95th Percentile: {response_times[p95_index]:.3f}s")
        print(f"  99th Percentile: {response_times[p99_index]:.3f}s")
        
        print(f"\n{'='*80}")
        print(f"VALIDATION CRITERIA")
        print(f"{'='*80}\n")
        
        criterion_1 = len(successful_bookings) == 1
        print(f"✓ Only 1 successful booking: {'PASS' if criterion_1 else 'FAIL'}")
        print(f"  Expected: 1, Got: {len(successful_bookings)}")
        
        criterion_2 = response_times[p95_index] < 1.5
        print(f"✓ 95th percentile < 1.5s: {'PASS' if criterion_2 else 'FAIL'}")
        print(f"  Expected: < 1.5s, Got: {response_times[p95_index]:.3f}s")
        
        criterion_3 = len(failed_bookings) == self.num_users - 1
        print(f"✓ Correct number of failures: {'PASS' if criterion_3 else 'FAIL'}")
        print(f"  Expected: {self.num_users - 1}, Got: {len(failed_bookings)}")
        
        all_passed = criterion_1 and criterion_2 and criterion_3
        
        print(f"\n{'='*80}")
        print(f"OVERALL RESULT: {'✓ PASS' if all_passed else '✗ FAIL'}")
        print(f"{'='*80}\n")
        
        if successful_bookings:
            print("Successful Booking Details:")
            for booking in successful_bookings:
                print(f"  User ID: {booking['user_id']}")
                print(f"  Response Time: {booking['response_time']:.3f}s")
                if booking.get('response_data'):
                    print(f"  Booking ID: {booking['response_data'].get('booking', {}).get('id')}")
        
        return all_passed

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Concurrent Booking Test')
    parser.add_argument('--url', default='http://localhost:5002/api', 
                       help='Booking service URL (default: http://localhost:5002/api)')
    parser.add_argument('--users', type=int, default=50,
                       help='Number of concurrent users (default: 50)')
    parser.add_argument('--room-id', type=int, default=1,
                       help='Room ID to test (default: 1)')
    parser.add_argument('--check-in', default=None,
                       help='Check-in date (YYYY-MM-DD, default: tomorrow)')
    parser.add_argument('--check-out', default=None,
                       help='Check-out date (YYYY-MM-DD, default: day after tomorrow)')
    parser.add_argument('--output', default='test_results.json',
                       help='Output file for results (default: test_results.json)')
    
    args = parser.parse_args()
    
    if not args.check_in:
        check_in_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
    else:
        check_in_date = args.check_in
    
    if not args.check_out:
        check_out_date = (datetime.now() + timedelta(days=3)).strftime('%Y-%m-%d')
    else:
        check_out_date = args.check_out
    
    print(f"\nTesting booking service at: {args.url}")
    print(f"Health check...")
    
    try:
        health_response = requests.get(f"{args.url}/health", timeout=5)
        if health_response.status_code == 200:
            print(f"✓ Service is healthy\n")
        else:
            print(f"✗ Service health check failed: {health_response.status_code}\n")
    except Exception as e:
        print(f"✗ Cannot connect to service: {e}\n")
        return
    
    test = ConcurrentBookingTest(args.url, args.users)
    results = test.run_concurrent_test(args.room_id, check_in_date, check_out_date)
    
    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\nDetailed results saved to: {args.output}")

if __name__ == '__main__':
    main()
