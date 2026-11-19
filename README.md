# Face Detection - Edge (Raspberry Pi)

CPU only, dependensi cuma OpenCV + NumPy. Image Docker kecil, tanpa torch/ultralytics.

## Method
| Method | Kecepatan | Catatan |
|--------|-----------|---------|
| `haar` | tercepat | wajah frontal saja |
| `yunet` (default) | cepat | lebih akurat, ada confidence (OpenCV `FaceDetectorYN`) |

## Jalankan (native)
```bash
pip install -r requirements.txt
python face_detection_app.py --method yunet            # dengan window, tekan q keluar
python face_detection_app.py --method haar --headless  # tanpa GUI (SSH/service)
```

## Kamera
- USB / V4L2: `--camera 0` (default)
- CSI Arducam IMX219: `--camera csi` (perlu `sudo apt install python3-picamera2`, jalankan native, bukan Docker)
- Setup/diagnosa CSI: `arducam_imx219_setup.sh`, `rpi_troubleshoot.sh`, `fix_camera.sh`

## Docker (kamera USB, headless)
```bash
docker compose up -d --build
docker compose logs -f
```
Log: `fps=.. faces=..` tiap 30 frame.

## File
```
face_detection_app.py  aplikasi (haar + yunet)
models/                yunet onnx + haar xml (~1 MB)
Dockerfile, docker-compose.yml, .dockerignore, requirements.txt
```
