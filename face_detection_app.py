#!/usr/bin/env python3
"""Face detection for edge devices (Raspberry Pi). CPU only, OpenCV only.

Methods:
  haar  - Haar cascade: fastest, frontal faces only
  yunet - YuNet (OpenCV FaceDetectorYN): more accurate, still light
"""

import argparse
import os
import sys
import time

import cv2

MODELS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models")
YUNET_PATH = os.path.join(MODELS, "face_detection_yunet_2023mar.onnx")
HAAR_PATH = os.path.join(MODELS, "haarcascade_frontalface_default.xml")


class HaarDetector:
    def __init__(self):
        self.cascade = cv2.CascadeClassifier(HAAR_PATH)
        if self.cascade.empty():
            raise RuntimeError(f"cannot load {HAAR_PATH}")

    def detect(self, frame):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = self.cascade.detectMultiScale(gray, 1.1, 5, minSize=(30, 30))
        return [(1.0, x, y, x + w, y + h) for x, y, w, h in faces]


class YuNetDetector:
    def __init__(self, width, height, threshold=0.7):
        if not os.path.exists(YUNET_PATH):
            raise RuntimeError(f"missing {YUNET_PATH}")
        self.det = cv2.FaceDetectorYN.create(YUNET_PATH, "", (width, height), threshold)

    def detect(self, frame):
        h, w = frame.shape[:2]
        self.det.setInputSize((w, h))
        _, faces = self.det.detect(frame)
        if faces is None:
            return []
        return [(float(f[14]), int(f[0]), int(f[1]), int(f[0] + f[2]), int(f[1] + f[3]))
                for f in faces]


class Camera:
    """V4L2/USB via OpenCV, or CSI (Arducam IMX219) via picamera2 if camera='csi'."""

    def __init__(self, camera, width, height):
        self.cap = self.pi = None
        if camera == "csi":
            from picamera2 import Picamera2  # apt install python3-picamera2
            self.pi = Picamera2()
            self.pi.configure(self.pi.create_video_configuration(
                main={"size": (width, height), "format": "BGR888"}))
            self.pi.start()
        else:
            self.cap = cv2.VideoCapture(int(camera))
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
            if not self.cap.isOpened():
                raise RuntimeError(f"cannot open camera {camera}")

    def read(self):
        if self.pi:
            return self.pi.capture_array()
        ok, frame = self.cap.read()
        return frame if ok else None

    def close(self):
        if self.pi:
            self.pi.stop()
        else:
            self.cap.release()


def main():
    p = argparse.ArgumentParser(description="Edge face detection")
    p.add_argument("--method", choices=["haar", "yunet"], default="yunet")
    p.add_argument("--camera", default="0", help="V4L2 index (0,1,...) or 'csi'")
    p.add_argument("--width", type=int, default=640)
    p.add_argument("--height", type=int, default=480)
    p.add_argument("--headless", action="store_true", help="no window, log only")
    args = p.parse_args()

    detector = (HaarDetector() if args.method == "haar"
                else YuNetDetector(args.width, args.height))
    cam = Camera(args.camera, args.width, args.height)
    print(f"method={args.method} camera={args.camera} headless={args.headless}", flush=True)

    frames, t0 = 0, time.time()
    try:
        while True:
            frame = cam.read()
            if frame is None:
                print("no frame", file=sys.stderr, flush=True)
                time.sleep(0.5)
                continue

            faces = detector.detect(frame)
            frames += 1
            if frames % 30 == 0:
                print(f"fps={frames / (time.time() - t0):.1f} faces={len(faces)}", flush=True)
                frames, t0 = 0, time.time()

            if args.headless:
                continue
            for conf, x1, y1, x2, y2 in faces:
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                cv2.putText(frame, f"{conf:.2f}", (x1, max(y1 - 8, 12)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
            cv2.imshow("faces", frame)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    except KeyboardInterrupt:
        pass
    finally:
        cam.close()
        if not args.headless:
            cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
