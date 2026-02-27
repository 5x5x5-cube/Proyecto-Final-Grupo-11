import psycopg2
import sys
from datetime import datetime

class DatabaseValidator:
    def __init__(self, booking_db_config, inventory_db_config):
        self.booking_db_config = booking_db_config
        self.inventory_db_config = inventory_db_config
    
    def connect_booking_db(self):
        return psycopg2.connect(**self.booking_db_config)
    
    def connect_inventory_db(self):
        return psycopg2.connect(**self.inventory_db_config)
    
    def validate_booking_consistency(self, room_id, check_in_date):
        print(f"\n{'='*80}")
        print(f"DATABASE VALIDATION")
        print(f"{'='*80}\n")
        
        print(f"Validating bookings for Room {room_id} on {check_in_date}...")
        
        booking_conn = self.connect_booking_db()
        inventory_conn = self.connect_inventory_db()
        
        try:
            booking_cursor = booking_conn.cursor()
            inventory_cursor = inventory_conn.cursor()
            
            booking_cursor.execute("""
                SELECT id, user_id, room_id, check_in_date, status, created_at
                FROM bookings
                WHERE room_id = %s AND check_in_date = %s
                ORDER BY created_at
            """, (room_id, check_in_date))
            
            bookings = booking_cursor.fetchall()
            
            print(f"\n1. BOOKING RECORDS")
            print(f"   Total bookings found: {len(bookings)}")
            
            if bookings:
                print(f"\n   Booking Details:")
                for booking in bookings:
                    print(f"   - ID: {booking[0]}, User: {booking[1]}, Status: {booking[4]}, Created: {booking[5]}")
            
            confirmed_bookings = [b for b in bookings if b[4] == 'confirmed']
            print(f"\n   Confirmed bookings: {len(confirmed_bookings)}")
            
            inventory_cursor.execute("""
                SELECT r.id, r.room_number, r.total_quantity, a.available_quantity, a.updated_at
                FROM rooms r
                LEFT JOIN availability a ON r.id = a.room_id
                WHERE r.id = %s AND a.date = %s
            """, (room_id, check_in_date))
            
            inventory_data = inventory_cursor.fetchone()
            
            print(f"\n2. INVENTORY STATUS")
            if inventory_data:
                room_id_db, room_number, total_quantity, available_quantity, updated_at = inventory_data
                print(f"   Room: {room_number} (ID: {room_id_db})")
                print(f"   Total Quantity: {total_quantity}")
                print(f"   Available Quantity: {available_quantity}")
                print(f"   Last Updated: {updated_at}")
                
                expected_available = total_quantity - len(confirmed_bookings)
                print(f"\n   Expected Available: {expected_available}")
                print(f"   Actual Available: {available_quantity}")
            else:
                print(f"   No inventory data found for room {room_id} on {check_in_date}")
                available_quantity = None
                total_quantity = None
            
            print(f"\n{'='*80}")
            print(f"VALIDATION RESULTS")
            print(f"{'='*80}\n")
            
            test_1 = len(confirmed_bookings) == 1
            print(f"✓ Test 1 - Only 1 confirmed booking: {'PASS' if test_1 else 'FAIL'}")
            print(f"  Expected: 1, Got: {len(confirmed_bookings)}")
            
            test_2 = len(bookings) > 1
            print(f"✓ Test 2 - Multiple booking attempts: {'PASS' if test_2 else 'FAIL'}")
            print(f"  Expected: > 1, Got: {len(bookings)}")
            
            test_3 = True
            if inventory_data and total_quantity is not None:
                expected_available = total_quantity - len(confirmed_bookings)
                test_3 = available_quantity == expected_available
                print(f"✓ Test 3 - Inventory consistency: {'PASS' if test_3 else 'FAIL'}")
                print(f"  Expected Available: {expected_available}, Got: {available_quantity}")
            else:
                print(f"✓ Test 3 - Inventory consistency: SKIP (no inventory data)")
            
            booking_cursor.execute("""
                SELECT user_id, COUNT(*) as booking_count
                FROM bookings
                WHERE room_id = %s AND check_in_date = %s AND status = 'confirmed'
                GROUP BY user_id
                HAVING COUNT(*) > 1
            """, (room_id, check_in_date))
            
            duplicate_bookings = booking_cursor.fetchall()
            
            test_4 = len(duplicate_bookings) == 0
            print(f"✓ Test 4 - No duplicate bookings per user: {'PASS' if test_4 else 'FAIL'}")
            if duplicate_bookings:
                print(f"  Found duplicate bookings for users: {duplicate_bookings}")
            
            all_passed = test_1 and test_2 and test_3 and test_4
            
            print(f"\n{'='*80}")
            print(f"OVERALL VALIDATION: {'✓ PASS' if all_passed else '✗ FAIL'}")
            print(f"{'='*80}\n")
            
            return all_passed
            
        finally:
            booking_conn.close()
            inventory_conn.close()
    
    def get_all_bookings(self):
        conn = self.connect_booking_db()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT id, user_id, room_id, check_in_date, check_out_date, 
                       total_price, status, created_at
                FROM bookings
                ORDER BY created_at DESC
            """)
            return cursor.fetchall()
        finally:
            conn.close()
    
    def get_inventory_status(self, room_id=None):
        conn = self.connect_inventory_db()
        try:
            cursor = conn.cursor()
            if room_id:
                cursor.execute("""
                    SELECT r.id, r.room_number, r.room_type, r.total_quantity,
                           a.date, a.available_quantity
                    FROM rooms r
                    LEFT JOIN availability a ON r.id = a.room_id
                    WHERE r.id = %s
                    ORDER BY a.date
                """, (room_id,))
            else:
                cursor.execute("""
                    SELECT r.id, r.room_number, r.room_type, r.total_quantity,
                           a.date, a.available_quantity
                    FROM rooms r
                    LEFT JOIN availability a ON r.id = a.room_id
                    ORDER BY r.id, a.date
                """)
            return cursor.fetchall()
        finally:
            conn.close()

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Validate booking database consistency')
    parser.add_argument('--booking-host', default='localhost', help='Booking DB host')
    parser.add_argument('--booking-port', type=int, default=5433, help='Booking DB port')
    parser.add_argument('--booking-db', default='booking_db', help='Booking database name')
    parser.add_argument('--booking-user', default='booking_user', help='Booking DB user')
    parser.add_argument('--booking-password', default='booking_pass', help='Booking DB password')
    
    parser.add_argument('--inventory-host', default='localhost', help='Inventory DB host')
    parser.add_argument('--inventory-port', type=int, default=5432, help='Inventory DB port')
    parser.add_argument('--inventory-db', default='inventory_db', help='Inventory database name')
    parser.add_argument('--inventory-user', default='inventory_user', help='Inventory DB user')
    parser.add_argument('--inventory-password', default='inventory_pass', help='Inventory DB password')
    
    parser.add_argument('--room-id', type=int, required=True, help='Room ID to validate')
    parser.add_argument('--check-in', required=True, help='Check-in date (YYYY-MM-DD)')
    
    args = parser.parse_args()
    
    booking_db_config = {
        'host': args.booking_host,
        'port': args.booking_port,
        'database': args.booking_db,
        'user': args.booking_user,
        'password': args.booking_password
    }
    
    inventory_db_config = {
        'host': args.inventory_host,
        'port': args.inventory_port,
        'database': args.inventory_db,
        'user': args.inventory_user,
        'password': args.inventory_password
    }
    
    validator = DatabaseValidator(booking_db_config, inventory_db_config)
    
    try:
        result = validator.validate_booking_consistency(args.room_id, args.check_in)
        sys.exit(0 if result else 1)
    except Exception as e:
        print(f"\n✗ Validation failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
