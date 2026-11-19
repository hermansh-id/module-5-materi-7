FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY face_detection_app.py .
COPY models/face_detection_yunet_2023mar.onnx models/haarcascade_frontalface_default.xml models/
ENTRYPOINT ["python", "face_detection_app.py"]
CMD ["--method", "yunet", "--headless"]
