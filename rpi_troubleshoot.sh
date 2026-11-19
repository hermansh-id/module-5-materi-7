#!/bin/bash

echo "🔧 Raspberry Pi 5 Face Detection Troubleshooting"
echo "================================================"

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  This script is designed for Raspberry Pi. You may be on a different system."
fi

echo ""
echo "📋 System Information:"
echo "----------------------"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "CPU: $(grep 'Model' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"

echo ""
echo "📷 Camera Status Check:"
echo "----------------------"

# Check if camera is enabled
if command -v vcgencmd &> /dev/null; then
    camera_status=$(vcgencmd get_camera)
    echo "Camera Status: $camera_status"
else
    echo "⚠️  vcgencmd not found (not running on Raspberry Pi)"
fi

# Check for video devices
echo ""
echo "Video Devices:"
if ls /dev/video* 1> /dev/null 2>&1; then
    ls -la /dev/video*
else
    echo "❌ No video devices found"
fi

# Check camera module
echo ""
echo "Camera Module Check:"
if lsmod | grep -q bcm2835; then
    echo "✅ Camera module loaded"
else
    echo "❌ Camera module not loaded"
fi

# Check if camera interface is enabled
echo ""
echo "Camera Interface Check:"
if [ -f /boot/config.txt ]; then
    if grep -q "camera_auto_detect=1" /boot/config.txt || grep -q "start_x=1" /boot/config.txt; then
        echo "✅ Camera interface appears to be enabled in config.txt"
    else
        echo "⚠️  Camera interface may not be enabled in config.txt"
        echo "   Run: sudo raspi-config → Interface Options → Camera"
    fi
else
    echo "⚠️  /boot/config.txt not found"
fi

echo ""
echo "🔧 Python Environment Check:"
echo "----------------------------"

# Check Python version
python_version=$(python3 --version 2>/dev/null || echo "Python3 not found")
echo "Python: $python_version"

# Check OpenCV
if python3 -c "import cv2; print('OpenCV version:', cv2.__version__)" 2>/dev/null; then
    echo "✅ OpenCV is installed"
else
    echo "❌ OpenCV is not installed"
    echo "   Run: pip3 install opencv-python"
fi

# Check if camera works with OpenCV
echo ""
echo "📹 OpenCV Camera Test:"
echo "--------------------"
python3 -c "
import cv2
import sys

print('Testing camera access...')
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print('❌ Camera not accessible with default backend')
    
    # Try different backends
    backends = [cv2.CAP_V4L2, cv2.CAP_V4L, cv2.CAP_ANY]
    for backend in backends:
        cap = cv2.VideoCapture(0, backend)
        if cap.isOpened():
            print(f'✅ Camera accessible with backend {backend}')
            break
    
    if not cap.isOpened():
        print('❌ Camera not accessible with any backend')
        sys.exit(1)
else:
    print('✅ Camera accessible with default backend')

# Try to read a frame
ret, frame = cap.read()
if ret:
    print(f'✅ Successfully read frame: {frame.shape}')
else:
    print('❌ Failed to read frame')

cap.release()
print('Camera test completed')
"

echo ""
echo "🖥️  Display Check:"
echo "----------------"

# Check if DISPLAY is set
if [ -n "$DISPLAY" ]; then
    echo "✅ DISPLAY variable is set: $DISPLAY"
else
    echo "⚠️  DISPLAY variable is not set"
    echo "   This may cause GUI issues"
fi

# Check if X11 is running
if pgrep -x "X" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    echo "✅ X11 server is running"
else
    echo "⚠️  X11 server is not running"
    echo "   This will prevent GUI from working"
fi

echo ""
echo "💡 Solutions for Common Issues:"
echo "==============================="

echo ""
echo "1. If camera is not detected:"
echo "   sudo raspi-config → Interface Options → Camera → Enable"
echo "   sudo reboot"

echo ""
echo "2. If camera is detected but not working:"
echo "   Check camera cable connection"
echo "   Try: sudo modprobe bcm2835-v4l2"

echo ""
echo "3. If GUI is not working:"
echo "   Run in headless mode: python3 face_detection_app.py --method haar --headless"
echo "   Or enable X11: sudo apt install x11-apps"

echo ""
echo "4. If performance is poor:"
echo "   Use Haar Cascade method (fastest)"
echo "   Lower camera resolution in code"
echo "   Close other applications"

echo ""
echo "5. If dependencies are missing:"
echo "   pip3 install -r requirements.txt"
echo "   sudo apt update && sudo apt install python3-pip"

echo ""
echo "🚀 Quick Test Commands:"
echo "======================"
echo "Test camera: python3 face_detection_app.py --method haar --headless"
echo "Test with GUI: python3 face_detection_app.py --method haar"
echo "Test different camera: python3 face_detection_app.py --method haar --camera 1"

echo ""
echo "✅ Troubleshooting complete!" 