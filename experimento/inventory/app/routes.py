from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
from .database import db
from .models import Room, Availability
import logging

inventory_bp = Blueprint('inventory', __name__)
logger = logging.getLogger(__name__)

@inventory_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'inventory'}), 200

@inventory_bp.route('/rooms', methods=['GET'])
def get_rooms():
    try:
        rooms = Room.query.all()
        return jsonify({
            'success': True,
            'rooms': [room.to_dict() for room in rooms]
        }), 200
    except Exception as e:
        logger.error(f"Error getting rooms: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@inventory_bp.route('/rooms/<int:room_id>', methods=['GET'])
def get_room(room_id):
    try:
        room = Room.query.get(room_id)
        if not room:
            return jsonify({'success': False, 'error': 'Room not found'}), 404
        
        return jsonify({
            'success': True,
            'room': room.to_dict()
        }), 200
    except Exception as e:
        logger.error(f"Error getting room {room_id}: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@inventory_bp.route('/rooms/<int:room_id>/availability', methods=['GET'])
def check_availability(room_id):
    try:
        date_str = request.args.get('date')
        if not date_str:
            return jsonify({'success': False, 'error': 'Date parameter required'}), 400
        
        date = datetime.strptime(date_str, '%Y-%m-%d').date()
        
        room = Room.query.get(room_id)
        if not room:
            return jsonify({'success': False, 'error': 'Room not found'}), 404
        
        availability = Availability.query.filter_by(
            room_id=room_id,
            date=date
        ).first()
        
        if not availability:
            availability = Availability(
                room_id=room_id,
                date=date,
                available_quantity=room.total_quantity
            )
            db.session.add(availability)
            db.session.commit()
        
        return jsonify({
            'success': True,
            'room_id': room_id,
            'date': date_str,
            'available_quantity': availability.available_quantity,
            'is_available': availability.available_quantity > 0
        }), 200
        
    except ValueError:
        return jsonify({'success': False, 'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
    except Exception as e:
        logger.error(f"Error checking availability: {str(e)}")
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@inventory_bp.route('/rooms/<int:room_id>/reserve', methods=['POST'])
def reserve_room(room_id):
    try:
        data = request.get_json()
        date_str = data.get('date')
        
        if not date_str:
            return jsonify({'success': False, 'error': 'Date required'}), 400
        
        date = datetime.strptime(date_str, '%Y-%m-%d').date()
        
        room = Room.query.get(room_id)
        if not room:
            return jsonify({'success': False, 'error': 'Room not found'}), 404
        
        availability = Availability.query.filter_by(
            room_id=room_id,
            date=date
        ).with_for_update().first()
        
        if not availability:
            availability = Availability(
                room_id=room_id,
                date=date,
                available_quantity=room.total_quantity
            )
            db.session.add(availability)
            db.session.flush()
        
        if availability.available_quantity <= 0:
            return jsonify({
                'success': False,
                'error': 'No availability for this date'
            }), 409
        
        availability.available_quantity -= 1
        availability.updated_at = datetime.utcnow()
        db.session.commit()
        
        logger.info(f"Room {room_id} reserved for {date_str}. Remaining: {availability.available_quantity}")
        
        return jsonify({
            'success': True,
            'message': 'Room reserved successfully',
            'remaining_quantity': availability.available_quantity
        }), 200
        
    except ValueError:
        return jsonify({'success': False, 'error': 'Invalid date format'}), 400
    except Exception as e:
        logger.error(f"Error reserving room: {str(e)}")
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@inventory_bp.route('/rooms/<int:room_id>/release', methods=['POST'])
def release_room(room_id):
    try:
        data = request.get_json()
        date_str = data.get('date')
        
        if not date_str:
            return jsonify({'success': False, 'error': 'Date required'}), 400
        
        date = datetime.strptime(date_str, '%Y-%m-%d').date()
        
        availability = Availability.query.filter_by(
            room_id=room_id,
            date=date
        ).with_for_update().first()
        
        if not availability:
            return jsonify({'success': False, 'error': 'Availability record not found'}), 404
        
        room = Room.query.get(room_id)
        if availability.available_quantity < room.total_quantity:
            availability.available_quantity += 1
            availability.updated_at = datetime.utcnow()
            db.session.commit()
            
            logger.info(f"Room {room_id} released for {date_str}. Available: {availability.available_quantity}")
            
            return jsonify({
                'success': True,
                'message': 'Room released successfully',
                'available_quantity': availability.available_quantity
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Cannot release, already at maximum capacity'
            }), 400
            
    except ValueError:
        return jsonify({'success': False, 'error': 'Invalid date format'}), 400
    except Exception as e:
        logger.error(f"Error releasing room: {str(e)}")
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500
