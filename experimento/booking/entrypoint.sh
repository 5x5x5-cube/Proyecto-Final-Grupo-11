#!/bin/bash
set -e

echo "Initializing database..."
python init_db.py

echo "Starting gunicorn..."
exec gunicorn --bind 0.0.0.0:5002 --workers 4 --timeout 120 "app:create_app()"
