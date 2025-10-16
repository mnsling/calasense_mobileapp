import pathlib
pathlib.WindowsPath = pathlib.PosixPath  # handle Windows-saved checkpoints on Linux

import io, os, time, base64
from datetime import datetime
from PIL import Image, ImageDraw
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import torch

print("Loading YOLOv5 model...")
model = torch.hub.load('/opt/yolov5', 'custom', path='model/model.pt', source='local')
print("Model loaded.")

load_dotenv()
app = Flask(__name__)
CORS(app)
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024  # 10MB

ALLOWED = {"jpg", "jpeg", "png", "bmp", "webp"}
def _allowed(name): return "." in name and name.rsplit(".", 1)[1].lower() in ALLOWED
def _now(): return datetime.utcnow().isoformat() + "Z"

@app.get("/health")
def health():
    return jsonify(status="ok", time=_now())

@app.post("/predict")
def predict():
    if "image" not in request.files:
        return jsonify(ok=False, error="No file 'image' found"), 400
    f = request.files["image"]
    if not f.filename:
        return jsonify(ok=False, error="No filename"), 400
    if not _allowed(f.filename):
        return jsonify(ok=False, error="Unsupported file type"), 415

    try:
        img = Image.open(io.BytesIO(f.read())).convert("RGB")
    except Exception as e:
        return jsonify(ok=False, error=f"Invalid image: {e}"), 400

    # Optional thresholds (uncomment to tweak)
    # model.conf = 0.25
    # model.iou  = 0.45

    t0 = time.time()
    results = model(img, size=640)
    df = results.pandas().xyxy[0]   # DataFrame with boxes

    # Build detections list (all boxes)
    detections = []
    for _, r in df.iterrows():
        detections.append({
            "bbox": [float(r["xmin"]), float(r["ymin"]), float(r["xmax"]), float(r["ymax"])],
            "confidence": float(r["confidence"]),
            "class_id": int(r["class"]),
            "class_name": str(r["name"]),
        })

    include_image = request.args.get("image", "false").lower() == "true"
    image_base64 = None

    if include_image:
        try:
            vis = img.copy()
            draw = ImageDraw.Draw(vis)
            for d in detections:
                x1, y1, x2, y2 = d["bbox"]
                lbl = f'{d["class_name"]} {d["confidence"]:.2f}'
                draw.rectangle([x1, y1, x2, y2], outline=(255, 0, 0), width=2)
                draw.text((x1, max(0, y1 - 12)), lbl, fill=(255, 0, 0))
            buf = io.BytesIO()
            vis.save(buf, format="JPEG", quality=85)
            image_base64 = base64.b64encode(buf.getvalue()).decode()
        except Exception as e:
            print(f"[predict] preview encode failed: {e}")

    elapsed_ms = int((time.time() - t0) * 1000)

    resp = {
        "ok": True,
        "detections": detections,  # list of boxes
        "meta": {
            "inference_ms": elapsed_ms,
            "width": img.width,
            "height": img.height,
            "timestamp": _now(),
        }
    }
    if image_base64:
        # put image earlier if you like; order is preserved in Python 3.7+
        resp["image_base64"] = image_base64

    return jsonify(resp)

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)


