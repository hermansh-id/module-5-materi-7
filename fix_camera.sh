#!/bin/bash

echo "🔧 Raspberry Pi 5 Camera Fix Script"
echo "==================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs sudo privileges for some operations"
    echo "   Run: sudo ./fix_camera.sh"
    exit 1
fi

echo ""
echo "📷 Step 1: Loading camera modules..."
echo "-----------------------------------"

# Load camera modules (fixed array syntax for better shell compatibility)
modules="bcm2835-v4l2 v4l2_common videodev"
for module in $modules; do
    echo "Loading $module..."
    modprobe $module 2>/dev/null
    if lsmod | grep -q $module; then
        echo "✅ $module loaded successfully"
    else
        echo "⚠️  $module not loaded (may not be available)"
    fi
done

echo ""
echo "🔧 Step 2: Checking camera interface..."
echo "--------------------------------------"

# Check if camera is enabled in config
if [ -f /boot/config.txt ]; then
    if grep -q "camera_auto_detect=1" /boot/config.txt || grep -q "start_x=1" /boot/config.txt; then
        echo "✅ Camera interface appears to be enabled"
    else
        echo "⚠️  Camera interface may not be enabled"
        echo "   You may need to run: sudo raspi-config"
        echo "   Then: Interface Options → Camera → Enable"
    fi
else
    echo "⚠️  /boot/config.txt not found"
fi

echo ""
echo "📹 Step 3: Checking video devices..."
echo "-----------------------------------"

# Check video devices
if ls /dev/video* 1> /dev/null 2>&1; then
    echo "✅ Video devices found:"
    ls -la /dev/video*
else
    echo "❌ No video devices found"
    echo "   This indicates a hardware or configuration issue"
fi

echo ""
echo "🧪 Step 4: Testing camera access..."
echo "----------------------------------"

# Test camera with Python
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
    print('   This may indicate a hardware issue or camera not properly connected')

cap.release()
print('Camera test completed')
"

echo ""
echo "💡 Step 5: Quick fixes to try..."
echo "--------------------------------"

echo "1. If camera is not detected:"
echo "   sudo raspi-config → Interface Options → Camera → Enable"
echo "   sudo reboot"

echo ""
echo "2. If camera is detected but not working:"
echo "   Check camera cable connection"
echo "   Ensure camera is properly seated"

echo ""
echo "3. If camera works but is slow:"
echo "   Use headless mode: python3 face_detection_app.py --method haar --headless"

echo ""
echo "4. Test the face detection app:"
echo "   python3 face_detection_app.py --method haar --headless"

echo ""
echo "✅ Camera fix script completed!" 