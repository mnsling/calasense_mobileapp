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
    if "image" not in request.files: return jsonify(error="No file 'image' found"), 400
    f = request.files["image"]
    if f.filename == "": return jsonify(error="No filename"), 400
    if not _allowed(f.filename): return jsonify(error="Unsupported file type"), 415

    try:
        img = Image.open(io.BytesIO(f.read())).convert("RGB")
    except Exception as e:
        return jsonify(error=f"Invalid image: {e}"), 400

    start = time.time()
    results = model(img, size=640)
    df = results.pandas().xyxy[0]
    top = None if df.empty else df.sort_values("confidence", ascending=False).iloc[0]
    elapsed = int((time.time() - start) * 1000)

    pred = {"class": None, "confidence": 0.0} if top is None else \
           {"class": str(top["name"]), "confidence": float(top["confidence"])}

    return jsonify(ok=True, prediction=pred, meta={
        "inference_ms": elapsed, "width": img.width, "height": img.height, "timestamp": _now()
    })

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
