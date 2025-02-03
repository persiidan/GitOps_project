from flask import Flask, jsonify, request
from flask_pymongo import PyMongo
from flask_cors import CORS
from bson import ObjectId
from datetime import datetime, timezone , timedelta
import os

app = Flask(__name__)
app.config["MONGO_URI"] = os.getenv("MONGO_URI", "mongodb://localhost:27017/app")
mongo = PyMongo(app)
CORS(app)

def convert_object_id(user):
    user['_id'] = str(user['_id'])
    return user

@app.route('/users', methods=['GET'])
def get_users():
    try:  
        users = list(mongo.db.users.find())
        return jsonify([convert_object_id(user) for user in users])
    except Exception as e:
        print(f"Error getting users: {e}") 
        return jsonify({'error': str(e)}), 500

@app.route('/users', methods=['POST'])
def add_user():
    try:  
        data = request.json
        print(f"Received data: {data}") 
        
        if 'username' in data and 'email' in data:
            result = mongo.db.users.insert_one({ 
                'username': data['username'],
                'email': data['email'],
                'created_at': datetime.now(timezone(timedelta(hours=2), "UTC+2")).isoformat()
            })
            new_user = mongo.db.users.find_one({'_id': result.inserted_id})
            return jsonify(convert_object_id(new_user)), 201
            
        return jsonify({'error': 'Invalid data'}), 400
    except Exception as e:
        print(f"Error adding user: {e}") 
        return jsonify({'error': str(e)}), 500

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    try: 
        result = mongo.db.users.delete_one({'_id': ObjectId(user_id)})
        if result.deleted_count:
            return jsonify({'message': 'User deleted successfully'}), 200
        return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        print(f"Error deleting user: {e}") 
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)