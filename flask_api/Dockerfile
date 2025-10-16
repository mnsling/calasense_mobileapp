FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System libs + git
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 git \
  && rm -rf /var/lib/apt/lists/*

# --- Clone YOLOv5 repo (v7.0 tag) into a fixed path ---
RUN git clone --depth 1 --branch v7.0 https://github.com/ultralytics/yolov5 /opt/yolov5
# ========================================== UPDATE THIS TO INSTEAD USE OUR YOLOV5 REPO ========================================================

# Copy only requirements first (for layer caching)
COPY requirements.txt .

# Base tooling
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# CPU-only Torch (reliable on slim)
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
    torch==2.2.2+cpu torchvision==0.17.2+cpu

# YOLOv5’s own python requirements (plus your app reqs)
RUN pip install --no-cache-dir -r /opt/yolov5/requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# (Optional) make YOLOv5 importable via PYTHONPATH, handy for utils
ENV PYTHONPATH="/opt/yolov5:${PYTHONPATH}"

# Copy your app (app.py, model.pt, etc.)
COPY . .

ENV PORT=5000
EXPOSE 5000

CMD ["python", "app.py"]