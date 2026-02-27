from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
from .database import db
from .models import Booking
from .redis_lock import create_booking_lock, get_redis_client
import requests
import logging
import time

booking_bp = Blueprint('booking', __name__)
logger = logging.getLogger(__name__)

@booking_bp.route('/health', methods=['GET'])
def health():
    try:
        redis_client = get_redis_client()
        redis_client.ping()
        redis_status = 'connected'
    except Exception as e:
        redis_status = f'error: {str(e)}'
    
    return jsonify({
        'status': 'healthy',
        'service': 'booking',
        'redis': redis_status
    }), 200

@booking_bp.route('/bookings/confirm', methods=['POST'])
def confirm_booking():
    start_time = time.time()
    
    try:
        data = request.get_json()
        
        user_id = data.get('user_id')
        room_id = data.get('room_id')
        check_in_date_str = data.get('check_in_date')
        check_out_date_str = data.get('check_out_date')
        
        if not all([user_id, room_id, check_in_date_str, check_out_date_str]):
            return jsonify({
                'success': False,
                'error': 'Missing required fields'
            }), 400
        
        check_in_date = datetime.strptime(check_in_date_str, '%Y-%m-%d').date()
        check_out_date = datetime.strptime(check_out_date_str, '%Y-%m-%d').date()
        
        if check_out_date <= check_in_date:
            return jsonify({
                'success': False,
                'error': 'Check-out date must be after check-in date'
            }), 400
        
        inventory_url = current_app.config['INVENTORY_SERVICE_URL']
        
        try:
            with create_booking_lock(room_id, check_in_date_str) as lock:
                logger.info(f"Lock acquired for room {room_id} on {check_in_date_str}")
                
                availability_response = requests.get(
                    f"{inventory_url}/rooms/{room_id}/availability",
                    params={'date': check_in_date_str},
                    timeout=5
                )
                
                if availability_response.status_code != 200:
                    return jsonify({
                        'success': False,
                        'error': 'Could not check room availability'
                    }), 500
                
                availability_data = availability_response.json()
                
                if not availability_data.get('is_available', False):
                    elapsed_time = time.time() - start_time
                    logger.warning(f"No availability for room {room_id} on {check_in_date_str}")
                    return jsonify({
                        'success': False,
                        'error': 'Room not available for selected date',
                        'response_time': f"{elapsed_time:.3f}s"
                    }), 409
                
                room_response = requests.get(
                    f"{inventory_url}/rooms/{room_id}",
                    timeout=5
                )
                
                if room_response.status_code != 200:
                    return jsonify({
                        'success': False,
                        'error': 'Could not get room information'
                    }), 500
                
                room_data = room_response.json()['room']
                price_per_night = room_data['price_per_night']
                
                num_nights = (check_out_date - check_in_date).days
                total_price = price_per_night * num_nights
                
                booking = Booking(
                    user_id=user_id,
                    room_id=room_id,
                    check_in_date=check_in_date,
                    check_out_date=check_out_date,
                    total_price=total_price,
                    status='pending'
                )
                
                db.session.add(booking)
                db.session.flush()
                
                reserve_response = requests.post(
                    f"{inventory_url}/rooms/{room_id}/reserve",
                    json={'date': check_in_date_str},
                    timeout=5
                )
                
                if reserve_response.status_code != 200:
                    db.session.rollback()
                    error_msg = reserve_response.json().get('error', 'Could not reserve room')
                    elapsed_time = time.time() - start_time
                    return jsonify({
                        'success': False,
                        'error': error_msg,
                        'response_time': f"{elapsed_time:.3f}s"
                    }), 409
                
                booking.status = 'confirmed'
                db.session.commit()
                
                elapsed_time = time.time() - start_time
                
                logger.info(f"Booking confirmed: ID={booking.id}, Room={room_id}, User={user_id}, Time={elapsed_time:.3f}s")
                
                return jsonify({
                    'success': True,
                    'message': 'Booking confirmed successfully',
                    'booking': booking.to_dict(),
                    'response_time': f"{elapsed_time:.3f}s"
                }), 201
                
        except Exception as lock_error:
            elapsed_time = time.time() - start_time
            logger.error(f"Lock error: {str(lock_error)}")
            return jsonify({
                'success': False,
                'error': 'Could not acquire lock for booking. Please try again.',
                'response_time': f"{elapsed_time:.3f}s"
            }), 503
            
    except ValueError as ve:
        return jsonify({
            'success': False,
            'error': f'Invalid date format: {str(ve)}'
        }), 400
    except requests.RequestException as re:
        logger.error(f"Inventory service error: {str(re)}")
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': 'Inventory service unavailable'
        }), 503
    except Exception as e:
        logger.error(f"Error confirming booking: {str(e)}")
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@booking_bp.route('/bookings/<int:booking_id>', methods=['GET'])
def get_booking(booking_id):
    try:
        booking = Booking.query.get(booking_id)
        if not booking:
            return jsonify({'success': False, 'error': 'Booking not found'}), 404
        
        return jsonify({
            'success': True,
            'booking': booking.to_dict()
        }), 200
    except Exception as e:
        logger.error(f"Error getting booking {booking_id}: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@booking_bp.route('/bookings/user/<int:user_id>', methods=['GET'])
def get_user_bookings(user_id):
    try:
        bookings = Booking.query.filter_by(user_id=user_id).all()
        return jsonify({
            'success': True,
            'bookings': [booking.to_dict() for booking in bookings]
        }), 200
    except Exception as e:
        logger.error(f"Error getting bookings for user {user_id}: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@booking_bp.route('/bookings', methods=['GET'])
def get_all_bookings():
    try:
        bookings = Booking.query.all()
        return jsonify({
            'success': True,
            'count': len(bookings),
            'bookings': [booking.to_dict() for booking in bookings]
        }), 200
    except Exception as e:
        logger.error(f"Error getting all bookings: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500
