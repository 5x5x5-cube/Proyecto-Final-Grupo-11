from app import create_app
from app.database import db
from app.models import Room, Availability
from datetime import datetime, timedelta

def init_sample_data():
    app = create_app()
    
    with app.app_context():
        db.create_all()
        
        if Room.query.count() == 0:
            rooms = [
                Room(
                    room_number='101',
                    room_type='Standard',
                    price_per_night=100.00,
                    total_quantity=1
                ),
                Room(
                    room_number='102',
                    room_type='Deluxe',
                    price_per_night=150.00,
                    total_quantity=2
                ),
                Room(
                    room_number='201',
                    room_type='Suite',
                    price_per_night=250.00,
                    total_quantity=1
                ),
                Room(
                    room_number='202',
                    room_type='Presidential',
                    price_per_night=500.00,
                    total_quantity=1
                )
            ]
            
            for room in rooms:
                db.session.add(room)
            
            db.session.commit()
            
            today = datetime.now().date()
            for room in rooms:
                for i in range(30):
                    date = today + timedelta(days=i)
                    availability = Availability(
                        room_id=room.id,
                        date=date,
                        available_quantity=room.total_quantity
                    )
                    db.session.add(availability)
            
            db.session.commit()
            print("Sample data initialized successfully!")
        else:
            print("Database already contains data. Skipping initialization.")

if __name__ == '__main__':
    init_sample_data()
