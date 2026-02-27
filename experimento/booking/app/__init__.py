from flask import Flask
from flask_cors import CORS
from .database import init_db

def create_app():
    app = Flask(__name__)
    app.config.from_object('app.config.Config')
    
    CORS(app)
    
    init_db(app)
    
    from .routes import booking_bp
    app.register_blueprint(booking_bp, url_prefix='/api')
    
    return app
