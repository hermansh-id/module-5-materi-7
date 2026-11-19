#!/bin/bash

echo "🔧 Raspberry Pi 5 Camera Interface Enabler (No GPU)"
echo "=================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (sudo)"
    echo "   Run: sudo ./enable_camera.sh"
    exit 1
fi

echo ""
echo "📷 Step 1: Checking current camera status..."
echo "-------------------------------------------"

# Check current camera status
if command -v vcgencmd &> /dev/null; then
    camera_status=$(vcgencmd get_camera 2>/dev/null || echo "Command failed")
    echo "Current camera status: $camera_status"
else
    echo "⚠️  vcgencmd not available"
fi

echo ""
echo "🔧 Step 2: Checking /boot/config.txt..."
echo "--------------------------------------"

if [ ! -f /boot/config.txt ]; then
    echo "❌ /boot/config.txt not found!"
    exit 1
fi

echo "✅ /boot/config.txt found"

# Check current camera settings
echo ""
echo "Current camera-related settings in config.txt:"
grep -i "camera\|start_x" /boot/config.txt || echo "No camera settings found"

echo ""
echo "📝 Step 3: Enabling camera interface (no GPU memory)..."
echo "------------------------------------------------------"

# Backup config file
cp /boot/config.txt /boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created: /boot/config.txt.backup"

# Check if camera is already enabled
if grep -q "camera_auto_detect=1" /boot/config.txt || grep -q "start_x=1" /boot/config.txt; then
    echo "✅ Camera interface appears to be already enabled"
else
    echo "🔧 Adding camera interface settings (no GPU memory allocation)..."
    
    # Add camera settings if not present (no GPU memory)
    if ! grep -q "camera_auto_detect=1" /boot/config.txt; then
        echo "camera_auto_detect=1" >> /boot/config.txt
        echo "✅ Added camera_auto_detect=1"
    fi
    
    if ! grep -q "start_x=1" /boot/config.txt; then
        echo "start_x=1" >> /boot/config.txt
        echo "✅ Added start_x=1"
    fi
    
    echo "ℹ️  Skipping GPU memory allocation (as requested)"
fi

echo ""
echo "📋 Step 4: Updated config.txt contents..."
echo "----------------------------------------"

echo "Camera-related settings:"
grep -i "camera\|start_x" /boot/config.txt || echo "No camera settings found"

echo ""
echo "⚠️  IMPORTANT: You need to reboot for changes to take effect!"
echo "=============================================================="

echo ""
echo "💡 Next steps:"
echo "1. Reboot your Raspberry Pi: sudo reboot"
echo "2. After reboot, test camera: python3 face_detection_app.py --method haar --headless"
echo "3. If still having issues, run: ./fix_camera.sh"

echo ""
echo "🚀 To reboot now, run: sudo reboot"
echo "✅ Camera interface enabler completed (no GPU memory allocation)!" 