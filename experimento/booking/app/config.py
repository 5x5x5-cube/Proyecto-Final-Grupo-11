import os

class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://booking_user:booking_pass@localhost:5433/booking_db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = True
    
    REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    REDIS_DB = int(os.getenv('REDIS_DB', 0))
    
    INVENTORY_SERVICE_URL = os.getenv('INVENTORY_SERVICE_URL', 'http://localhost:5001/api')
    
    LOCK_TIMEOUT = 10
    LOCK_RETRY_ATTEMPTS = 3
    LOCK_RETRY_DELAY = 0.1
