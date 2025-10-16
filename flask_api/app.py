import pathlib
pathlib.WindowsPath = pathlib.PosixPath

import io, os, time
from datetime import datetime
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import torch
import base64

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
    if not _allowed(f.filename):
        return jsonify(error="Unsupported file type"), 415

    try:
        img = Image.open(io.BytesIO(f.read())).convert("RGB")
    except Exception as e:
        return jsonify(error=f"Invalid image: {e}"), 400

    # ---- optional thresholds while testing ----
    # model.conf = 0.25  # confidence threshold
    # model.iou  = 0.45  # NMS IoU threshold

    start = time.time()
    results = model(img, size=640)
    df = results.pandas().xyxy[0]  # DataFrame of detections

    # Build detections list
    detections = []
    for _, r in df.iterrows():
        detections.append({
            "bbox": [float(r["xmin"]), float(r["ymin"]), float(r["xmax"]), float(r["ymax"])],
            "confidence": float(r["confidence"]),
            "class_id": int(r["class"]),
            "class_name": str(r["name"]),
        })

    # Draw boxes with PIL (avoids OpenCV writeability issues)
    from PIL import ImageDraw  # (font optional)
    vis = img.copy()
    draw = ImageDraw.Draw(vis)
    for d in detections:
        x1, y1, x2, y2 = d["bbox"]
        label = f'{d["class_name"]} {d["confidence"]:.2f}'
        draw.rectangle([x1, y1, x2, y2], outline=(255, 0, 0), width=2)
        draw.text((x1, max(0, y1 - 12)), label, fill=(255, 0, 0))

    # Encode preview as Base64 JPEG
    buf = io.BytesIO()
    vis.save(buf, format="JPEG", quality=85)
    image_base64 = base64.b64encode(buf.getvalue()).decode()

    elapsed_ms = int((time.time() - start) * 1000)

    return jsonify(
        detections=detections,
        ok=True,
        image_base64=image_base64,
        meta={
            "inference_ms": elapsed_ms,
            "width": img.width,
            "height": img.height,
            "timestamp": _now()
        }
    )

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
