import os
import uuid
import os 
api_key = os.getenv("API_KEY")
from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, storage, firestore
import requests


# ------------------- Import your custom functions -------------------
# Adjust the import names according to your actual file/module names
from background_remover import remove_bg_transparent
from object_remover import interactive_inpaint
from image_enhancer import auto_enhance

# ------------------- Firebase Setup -------------------

# Replace with your actual service account key file path
cred = credentials.Certificate("serviceAccountKey.json")

# Initialize Firebase Admin SDK (no storage bucket needed)
firebase_admin.initialize_app(cred)
db = firestore.client()


# ------------------- Flask App -------------------
from werkzeug.exceptions import HTTPException

app = Flask(__name__)
CORS(app)  # Allow Flutter emulator access

@app.errorhandler(Exception)
def handle_exception(e):
    if isinstance(e, HTTPException):
        return jsonify({"error": str(e)}), e.code
    return jsonify({"error": str(e)}), 500

TEMP_DIR = "temp_uploads"
os.makedirs(TEMP_DIR, exist_ok=True)

# ------------------- Helper: Upload to Firebase -------------------
def upload_to_imgbb(image_bytes: bytes, original_filename: str, api_key: str) -> str:
    """Upload image bytes to ImgBB and return the public URL."""
    url = "https://api.imgbb.com/1/upload"
    payload = {
        "key": api_key,
    }
    files = {
        "image": (original_filename, image_bytes, "image/png")
    }
    # Add a timeout so backend doesn't hang indefinitely when ImgBB is slow.
    response = requests.post(url, data=payload, files=files, timeout=60)
    if response.status_code != 200:
        raise Exception(f"ImgBB upload failed: {response.text}")
    data = response.json()
    if not data.get("success"):
        raise Exception(f"ImgBB error: {data.get('error', {}).get('message')}")
    return data["data"]["url"]



def save_metadata(original_filename: str, result_url: str, storage_path: str, operation: str):
    doc_ref = db.collection("processed_images").document()
    doc_ref.set({
        "original_filename": original_filename,
        "result_url": result_url,   # ImgBB URL
        "operation": operation,
        "created_at": firestore.SERVER_TIMESTAMP
    })
    return doc_ref.id



# ------------------- Helper: Process uploaded file -------------------
def process_with_function(file, processing_func, operation_name, api_key: str, **func_kwargs):
    temp_path = os.path.join(TEMP_DIR, uuid.uuid4().hex + "_" + file.filename)
    file.save(temp_path)
    output_path = None
    try:
        output_path = processing_func(temp_path, **func_kwargs)
        with open(output_path, "rb") as f:
            output_bytes = f.read()
        # Upload to ImgBB instead of Firebase Storage
        image_url = upload_to_imgbb(output_bytes, file.filename, api_key)
        # Save only metadata to Firestore (no storage path needed now)
        doc_id = save_metadata(file.filename, image_url, "", operation_name)
        return jsonify({"success": True, "result_url": image_url, "image_id": doc_id}), 200
    except Exception as e:
        return jsonify({"error": f"{operation_name} failed: {str(e)}"}), 500
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        if output_path and os.path.exists(output_path):
            os.remove(output_path)



# ------------------- 1. Background Removal Endpoint -------------------
@app.route('/remove_background', methods=['POST'])
def remove_background():
    if 'image' not in request.files:
        return jsonify({"error": "No image file"}), 400
    file = request.files['image']
    return process_with_function(
        file,
        remove_bg_transparent,
        "background_removal",
        api_key,
    )
    # The JSON response is already built inside process_with_function, so we just return it directly.


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "service": "backend"}), 200


# ------------------- 2. Text Removal Endpoint -------------------
@app.route('/remove_text', methods=['POST'])
def remove_text():
    if 'image' not in request.files:
        return jsonify({"error": "No image file"}), 400
    file = request.files['image']
    try:
        from text_remover import remove_text_from_image
    except Exception as e:
        return jsonify({"error": f"Text removal module import failed: {e}"}), 500
    return process_with_function(
        file,
        remove_text_from_image,
        "text_removal",
        api_key,
    )


# ------------------- 3. Object Removal Endpoint -------------------
@app.route('/remove_object', methods=['POST'])
def remove_object():
    if 'image' not in request.files:
        return jsonify({"error": "No image file"}), 400
    file = request.files['image']
    return process_with_function(
        file,
        interactive_inpaint,
        "object_removal",
        api_key,
    )

# ------------------- 4. Image Enhancement Endpoint -------------------
@app.route('/enhance_image', methods=['POST'])
def enhance_image():
    if 'image' not in request.files:
        return jsonify({"error": "No image file"}), 400
    file = request.files['image']
    strength = float(request.form.get('strength', 1.0))
    def enhance_wrapper(path):
        return auto_enhance(path, strength=strength)
    return process_with_function(
        file,
        enhance_wrapper,
        "image_enhancement",
        api_key,
    )

# ------------------- Run -------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)