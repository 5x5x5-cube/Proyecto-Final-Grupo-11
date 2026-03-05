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
                "timestamp": datetime.now().isoformat()
            }

        except requests.exceptions.Timeout:

            elapsed_time = time.time() - start_time

            result = {
                "user_id": user_id,
                "status_code": 503,
                "response_time": elapsed_time,
                "success": False,
                "error": "Timeout",
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:

            elapsed_time = time.time() - start_time

            result = {
                "user_id": user_id,
                "status_code": 500,
                "response_time": elapsed_time,
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

        with self.lock:
            self.results.append(result)

        return result

    def run_concurrent_test(self, room_id, check_in_date, check_out_date):

        print("\n" + "=" * 80)
        print("CONCURRENT BOOKING TEST")
        print("=" * 80)

        print(f"Room ID: {room_id}")
        print(f"Concurrent Users: {self.num_users}")

        print("\nScenario:")
        print(f"Users 1-{self.num_users//2}: {check_in_date} → {check_out_date}")
        print(f"Users {self.num_users//2}-{self.num_users}: overlap reservation")

        print("=" * 80 + "\n")

        self.results = []
        threads = []

        test_start_time = time.time()

        for i in range(self.num_users):

            user_id = 1000 + i

            # mitad usa rango base
            if i < self.num_users // 2:

                check_in = check_in_date
                check_out = check_out_date

            else:

                # rango solapado
                overlap_start = datetime.strptime(check_in_date, "%Y-%m-%d") + timedelta(days=1)
                overlap_end = datetime.strptime(check_out_date, "%Y-%m-%d") + timedelta(days=1)

                check_in = overlap_start.strftime("%Y-%m-%d")
                check_out = overlap_end.strftime("%Y-%m-%d")

            thread = threading.Thread(
                target=self.make_booking_request,
                args=(user_id, room_id, check_in, check_out)
            )

            threads.append(thread)

        for t in threads:
            t.start()

        for t in threads:
            t.join()

        total_test_time = time.time() - test_start_time

        self.analyze_results(total_test_time)

        return self.results

    def analyze_results(self, total_test_time):

        print("\n" + "=" * 80)
        print("TEST RESULTS ANALYSIS")
        print("=" * 80 + "\n")

        successful = [r for r in self.results if r["status_code"] == 201]
        conflicts = [r for r in self.results if r["status_code"] == 409]
        unavailable = [r for r in self.results if r["status_code"] == 503]
        server_errors = [r for r in self.results if r["status_code"] == 500]

        response_times = [r["response_time"] for r in self.results]
        response_times.sort()

        status_codes = defaultdict(int)

        for r in self.results:
            status_codes[r["status_code"]] += 1

        print(f"Total Requests: {len(self.results)}")

        print("\nHTTP Status Distribution:")

        for code, count in sorted(status_codes.items()):
            print(f"  {code}: {count}")

        print("\nError Classification:")

        print(f"  409 Conflict (expected): {len(conflicts)}")
        print(f"  503 Service Unavailable: {len(unavailable)}")
        print(f"  500 Internal Server Error: {len(server_errors)}")

        print("\n" + "=" * 80)
        print("PERFORMANCE METRICS")
        print("=" * 80 + "\n")

        print(f"Total Test Duration: {total_test_time:.3f}s")

        print("\nResponse Times:")

        print(f"  Min: {min(response_times):.3f}s")
        print(f"  Max: {max(response_times):.3f}s")
        print(f"  Avg: {sum(response_times)/len(response_times):.3f}s")

        p95 = response_times[int(len(response_times)*0.95)]
        p99 = response_times[int(len(response_times)*0.99)]

        print(f"  P95: {p95:.3f}s")
        print(f"  P99: {p99:.3f}s")

        throughput = len(self.results) / total_test_time

        print(f"\nThroughput: {throughput:.2f} requests/sec")

        print("\n" + "=" * 80)
        print("VALIDATION CRITERIA")
        print("=" * 80 + "\n")

        criterion_1 = len(successful) == 1
        print(f"Only 1 successful booking: {'PASS' if criterion_1 else 'FAIL'}")

        criterion_2 = p95 < 1.5
        print(f"P95 < 1.5 seconds: {'PASS' if criterion_2 else 'FAIL'}")

        criterion_3 = len(server_errors) == 0
        print(f"No system errors (500): {'PASS' if criterion_3 else 'FAIL'}")

        print("\n" + "=" * 80)

        summary = {

            "total_requests": len(self.results),
            "success": len(successful),
            "conflicts": len(conflicts),
            "unavailable": len(unavailable),
            "server_errors": len(server_errors),
            "p95_latency": p95,
            "p99_latency": p99,
            "throughput": throughput
        }

        with open("summary_results.json", "w") as f:
            json.dump(summary, f, indent=2)

        print("\nSummary saved to summary_results.json")


def main():

    import argparse

    parser = argparse.ArgumentParser()

    parser.add_argument("--url", default="http://localhost:5002/api")
    parser.add_argument("--users", type=int, default=50)
    parser.add_argument("--room-id", type=int, default=1)

    parser.add_argument("--check-in", default=None)
    parser.add_argument("--check-out", default=None)

    parser.add_argument("--output", default="test_results.json")

    args = parser.parse_args()

    if args.check_in:
        check_in = args.check_in
    else:
        check_in = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

    if args.check_out:
        check_out = args.check_out
    else:
        check_out = (datetime.now() + timedelta(days=5)).strftime("%Y-%m-%d")

    print("\nHealth check...")

    try:

        health = requests.get(f"{args.url}/health", timeout=5)

        if health.status_code == 200:
            print("Service is healthy\n")
        else:
            print("Health check failed\n")
            return

    except Exception as e:

        print(f"Cannot connect to service: {e}")
        return

    test = ConcurrentBookingTest(args.url, args.users)

    results = test.run_concurrent_test(args.room_id, check_in, check_out)

    with open(args.output, "w") as f:
        json.dump(results, f, indent=2)

    print(f"\nDetailed results saved to {args.output}")


if __name__ == "__main__":
    main()