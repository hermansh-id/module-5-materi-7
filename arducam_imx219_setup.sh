#!/bin/bash

echo "🔧 Arducam IMX219 Camera Setup for Raspberry Pi 5"
echo "================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs sudo privileges for some operations"
    echo "   Run: sudo ./arducam_imx219_setup.sh"
    exit 1
fi

echo ""
echo "📷 Step 1: Checking Arducam IMX219 compatibility..."
echo "--------------------------------------------------"

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  This script is designed for Raspberry Pi"
fi

echo ""
echo "🔧 Step 2: Checking current camera interface..."
echo "----------------------------------------------"

# Check if camera interface is enabled
if [ -f /boot/config.txt ]; then
    echo "Current camera settings in /boot/config.txt:"
    grep -i "camera\|start_x\|dtoverlay" /boot/config.txt || echo "No camera settings found"
else
    echo "❌ /boot/config.txt not found"
    exit 1
fi

echo ""
echo "📹 Step 3: Testing with libcamera..."
echo "-----------------------------------"

# Test if libcamera is working
if command -v libcamera-hello &> /dev/null; then
    echo "✅ libcamera-hello is available"
    echo "Testing libcamera-hello (5 second test)..."
    timeout 5 libcamera-hello --info 2>/dev/null || echo "libcamera-hello test completed"
else
    echo "⚠️  libcamera-hello not found"
    echo "   Install with: sudo apt install libcamera-tools"
fi

echo ""
echo "🔧 Step 4: Configuring for Arducam IMX219..."
echo "-------------------------------------------"

# Backup config file
cp /boot/config.txt /boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created: /boot/config.txt.backup"

# Check if IMX219 overlay is already configured
if grep -q "imx219" /boot/config.txt; then
    echo "✅ IMX219 overlay already configured"
else
    echo "🔧 Adding IMX219 overlay with cam0..."
    
    # Add IMX219 overlay with cam0 parameter
    if ! grep -q "dtoverlay=imx219,cam0" /boot/config.txt; then
        echo "dtoverlay=imx219,cam0" >> /boot/config.txt
        echo "✅ Added dtoverlay=imx219,cam0"
    fi
fi

# Enable camera interface if not already enabled
if ! grep -q "camera_auto_detect=1" /boot/config.txt && ! grep -q "start_x=1" /boot/config.txt; then
    echo "camera_auto_detect=1" >> /boot/config.txt
    echo "✅ Added camera_auto_detect=1"
fi

echo ""
echo "📋 Step 5: Updated config.txt contents..."
echo "----------------------------------------"

echo "Camera-related settings:"
grep -i "camera\|start_x\|dtoverlay\|imx219" /boot/config.txt || echo "No camera settings found"

echo ""
echo "⚠️  IMPORTANT: You need to reboot for changes to take effect!"
echo "=============================================================="

echo ""
echo "💡 Next steps:"
echo "1. Reboot your Raspberry Pi: sudo reboot"
echo "2. After reboot, test libcamera: libcamera-hello"
echo "3. Test OpenCV: python3 arducam_test.py"
echo "4. Test face detection: python3 face_detection_app.py --method haar --headless"

echo ""
echo "🚀 To reboot now, run: sudo reboot"
echo "✅ Arducam IMX219 setup completed!" 