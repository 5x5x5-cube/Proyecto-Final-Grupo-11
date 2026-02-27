import redis
import uuid
import time
import logging
from flask import current_app

logger = logging.getLogger(__name__)

class RedisLock:
    def __init__(self, redis_client, lock_key, timeout=10):
        self.redis_client = redis_client
        self.lock_key = lock_key
        self.timeout = timeout
        self.lock_value = str(uuid.uuid4())
        self.acquired = False
    
    def acquire(self, retry_attempts=3, retry_delay=0.1):
        for attempt in range(retry_attempts):
            acquired = self.redis_client.set(
                self.lock_key,
                self.lock_value,
                nx=True,
                ex=self.timeout
            )
            
            if acquired:
                self.acquired = True
                logger.info(f"Lock acquired: {self.lock_key} (attempt {attempt + 1})")
                return True
            
            if attempt < retry_attempts - 1:
                time.sleep(retry_delay * (2 ** attempt))
        
        logger.warning(f"Failed to acquire lock: {self.lock_key} after {retry_attempts} attempts")
        return False
    
    def release(self):
        if not self.acquired:
            return False
        
        lua_script = """
        if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
        else
            return 0
        end
        """
        
        try:
            result = self.redis_client.eval(lua_script, 1, self.lock_key, self.lock_value)
            if result:
                logger.info(f"Lock released: {self.lock_key}")
                self.acquired = False
                return True
            else:
                logger.warning(f"Lock already expired or owned by another process: {self.lock_key}")
                return False
        except Exception as e:
            logger.error(f"Error releasing lock {self.lock_key}: {str(e)}")
            return False
    
    def __enter__(self):
        retry_attempts = current_app.config.get('LOCK_RETRY_ATTEMPTS', 3)
        retry_delay = current_app.config.get('LOCK_RETRY_DELAY', 0.1)
        
        if not self.acquire(retry_attempts=retry_attempts, retry_delay=retry_delay):
            raise Exception(f"Could not acquire lock: {self.lock_key}")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.release()
        return False

def get_redis_client():
    return redis.Redis(
        host=current_app.config['REDIS_HOST'],
        port=current_app.config['REDIS_PORT'],
        db=current_app.config['REDIS_DB'],
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5
    )

def create_booking_lock(room_id, date):
    redis_client = get_redis_client()
    lock_key = f"lock:room:{room_id}:{date}"
    timeout = current_app.config.get('LOCK_TIMEOUT', 10)
    return RedisLock(redis_client, lock_key, timeout)
