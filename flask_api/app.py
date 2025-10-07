import io
import os
import time
from datetime import datetime
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # allow all origins for dev

# 10 MB upload limit
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024

# --- Helpers ---
ALLOWED_EXT = {"jpg", "jpeg", "png", "bmp", "webp"}

def _allowed(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXT

def _now_iso() -> str:
    return datetime.utcnow().isoformat() + "Z"


# --- Routes ---
@app.get("/health")
def health():
    return jsonify(status="ok", time=_now_iso())

@app.get("/version")
def version():
    return jsonify(
        api="calasense-flask",
        version="0.1.0",
        model_loaded=False,  # will change to True when YOLO added
        time=_now_iso()
    )

@app.post("/predict")
def predict():
    """Accepts image upload and returns dummy result for now"""
    if "image" not in request.files:
        return jsonify(error="No file part 'image' found"), 400

    file = request.files["image"]

    if file.filename == "":
        return jsonify(error="No selected file"), 400
    if not _allowed(file.filename):
        return jsonify(error="Unsupported file type"), 415

    # Verify it’s an image
    try:
        image_bytes = file.read()
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        return jsonify(error=f"Invalid image: {e}"), 400

    # Dummy prediction for now
    start = time.time()
    time.sleep(0.15)  # simulate inference time
    dummy = {
        "class": "Leaf Blight",   # replace later with YOLO output
        "confidence": 0.87,
    }
    elapsed_ms = int((time.time() - start) * 1000)

    return jsonify(
        ok=True,
        prediction=dummy,
        meta={
            "inference_ms": elapsed_ms,
            "width": img.width,
            "height": img.height,
            "timestamp": _now_iso(),
        }
    )


# --- Future YOLO integration example ---
# from ultralytics import YOLO
# model = YOLO("runs/train/weights/best.pt")
#
# def yolo_predict_pil(pil_img):
#     results = model.predict(pil_img, imgsz=640, conf=0.25, verbose=False)[0]
#     conf = max(results.probs.data.tolist())
#     cls_idx = int(results.probs.top1)
#     cls_name = model.names[cls_idx]
#     return {"class": cls_name, "confidence": float(conf)}


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)
