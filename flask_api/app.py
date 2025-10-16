import pathlib
pathlib.WindowsPath = pathlib.PosixPath

import io, os, time
from datetime import datetime
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import torch

print("Loading YOLOv5 model...")
model = torch.hub.load('/opt/yolov5', 'custom', path='model.pt', source='local')
print("Model loaded succesfully.")

load_dotenv()
app = Flask(__name__)
CORS(app)
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024

ALLOWED_EXT = {"jpg", "jpeg", "png", "bmp", "webp"}
def _allowed(fn): return "." in fn and fn.rsplit(".", 1)[1].lower() in ALLOWED_EXT
def _now(): return datetime.utcnow().isoformat() + "Z"

@app.get("/health")
def health(): return jsonify(status="ok", time=_now())

@app.post("/predict")
def predict():
    if "image" not in request.files:
        return jsonify(error="No file 'image' found"), 400
    f = request.files["image"]
    if f.filename == "":
        return jsonify(error="No filename"), 400


    try:
        img = Image.open(io.BytesIO(f.read())).convert("RGB")
    except Exception as e:
        return jsonify(error=f"Invalid image: {e}"), 400


    start = time.time()
    results = model(img, size=640)
    df = results.pandas().xyxy[0]


    # --- Build detections list ---
    detections = []
    for _, r in df.iterrows():
        detections.append({
            "bbox": [float(r["xmin"]), float(r["ymin"]), float(r["xmax"]), float(r["ymax"])],
            "confidence": float(r["confidence"]),
            "class_id": int(r["class"]),
            "class_name": str(r["name"]),
        })


    # --- Draw bounding boxes on the image ---
    results.render()  # YOLOv5 draws boxes directly on results.ims[0]
    boxed_image = Image.fromarray(results.ims[0])


    # Convert to base64
    import base64
    buf = io.BytesIO()
    boxed_image.save(buf, format="JPEG", quality=85)
    image_base64 = base64.b64encode(buf.getvalue()).decode()


    elapsed_ms = int((time.time() - start) * 1000)


    return jsonify(
        ok=True,
        detections=detections,
        meta={
            "inference_ms": elapsed_ms,
            "width": img.width,
            "height": img.height,
            "timestamp": _now()
        },
        image_base64=image_base64  
    )

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
