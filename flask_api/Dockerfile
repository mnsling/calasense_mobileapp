FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps needed by OpenCV + git
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 git \
  && rm -rf /var/lib/apt/lists/*

# Pre-copy requirements (for caching)
COPY yolov5/requirements.txt /opt/yolov5/requirements.txt
COPY requirements.txt /app/requirements.txt

# Python tooling
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# CPU Torch (works well on slim)
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
    torch==2.2.2+cpu torchvision==0.17.2+cpu

# YOLOv5 + app deps
RUN pip install --no-cache-dir -r /opt/yolov5/requirements.txt && \
    pip install --no-cache-dir -r /app/requirements.txt

# Copy sources
COPY yolov5 /opt/yolov5
ENV PYTHONPATH="/opt/yolov5:$PYTHONPATH"

COPY . /app

ENV PORT=5000
EXPOSE 5000
CMD ["python", "app.py"]



