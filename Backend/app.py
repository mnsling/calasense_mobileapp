from flask import Flask, request, jsonify, send_file
import torch
import os
from werkzeug.utils import secure_filename
import uuid
import cv2
import pandas as pd

app = Flask(__name__)

# Load YOLOv5 model (local weights)
model = torch.hub.load('yolov5', 'custom',
                       path='model/model_bifpn_ca+_rgb.pt',
                       source='local')

UPLOAD_FOLDER = 'data/uploads'
RESULTS_FOLDER = 'data/results'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

CONF_THRESHOLD = 0.3


@app.route('/detect', methods=['POST'])
def detect():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    file = request.files['image']
    filename = secure_filename(file.filename)
    unique_name = f"{uuid.uuid4().hex}_{filename}"
    filepath = os.path.join(UPLOAD_FOLDER, unique_name)
    file.save(filepath)

    # Run YOLOv5 detection
    results = model(filepath)
    detections = results.pandas().xyxy[0]
    filtered = detections[detections['confidence'] >= CONF_THRESHOLD]
    detections_list = filtered.to_dict(orient="records")

    # --- Draw bounding boxes manually ---
    image = cv2.imread(filepath)
    for _, det in filtered.iterrows():
        xmin, ymin, xmax, ymax = int(det['xmin']), int(det['ymin']), int(det['xmax']), int(det['ymax'])
        label = f"{det['name']} ({det['confidence']:.2f})"
        # draw rectangle
        cv2.rectangle(image, (xmin, ymin), (xmax, ymax), (0, 255, 0), 2)
        # draw label
        cv2.putText(image, label, (xmin, ymin - 10), cv2.FONT_HERSHEY_SIMPLEX, 
                    0.6, (0, 255, 0), 2)

    # Save annotated image
    annotated_path = os.path.join(RESULTS_FOLDER, f"annotated_{unique_name}")
    cv2.imwrite(annotated_path, image)

    return jsonify({
        'message': 'Detection complete',
        'detections': detections_list,
        'annotated_url': f'/results/{os.path.basename(annotated_path)}'
    })


@app.route('/results/<filename>', methods=['GET'])
def get_result(filename):
    """Serve annotated images."""
    return send_file(os.path.join(RESULTS_FOLDER, filename), mimetype='image/jpeg')


@app.route('/', methods=['GET'])
def index():
    return "YOLOv5 Flask API is running!"


if __name__ == '__main__':
    app.run(port=5000, debug=True)
