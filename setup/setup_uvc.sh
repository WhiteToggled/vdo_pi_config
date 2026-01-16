#!/bin/bash
# --- 1. DEFINE PATHS ---
G=/sys/kernel/config/usb_gadget/g1

# --- 2. CLEANUP ---
if [ -d "$G" ]; then
    echo "Cleaning up existing gadget..."
    echo "" | sudo tee $G/UDC > /dev/null || true
    sudo find $G/configs/c.1/ -maxdepth 1 -type l -delete 2>/dev/null || true
    sudo find $G -depth -type d -exec rmdir {} \; 2>/dev/null || true
fi

# --- 3. CREATE GADGET ---
sudo mkdir -p $G
echo 0x1d6b | sudo tee $G/idVendor > /dev/null
echo 0x0104 | sudo tee $G/idProduct > /dev/null
echo 0x0200 | sudo tee $G/bcdUSB > /dev/null
echo 0xef | sudo tee $G/bDeviceClass > /dev/null
echo 0x02 | sudo tee $G/bDeviceSubClass > /dev/null
echo 0x01 | sudo tee $G/bDeviceProtocol > /dev/null

sudo mkdir -p $G/strings/0x409
echo "1234567890" | sudo tee $G/strings/0x409/serialnumber > /dev/null
echo "Raspberry Pi" | sudo tee $G/strings/0x409/manufacturer > /dev/null
echo "Pi USB Webcam" | sudo tee $G/strings/0x409/product > /dev/null

# --- 4. UVC FUNCTION (The Strict Part) ---
# We create the format folder before the frame folder
sudo mkdir -p $G/functions/uvc.0/control/header/h
sudo mkdir -p $G/functions/uvc.0/streaming/mjpeg/m/f1

# Frame Settings (1280x720)
echo 1280 | sudo tee $G/functions/uvc.0/streaming/mjpeg/m/f1/wWidth > /dev/null
echo 720 | sudo tee $G/functions/uvc.0/streaming/mjpeg/m/f1/wHeight > /dev/null
echo 1843200 | sudo tee $G/functions/uvc.0/streaming/mjpeg/m/f1/dwMaxVideoFrameBufferSize > /dev/null
echo 333333 | sudo tee $G/functions/uvc.0/streaming/mjpeg/m/f1/dwFrameInterval > /dev/null

# --- 5. HEADERS & LINKING ---
sudo mkdir -p $G/functions/uvc.0/streaming/header/h
sudo ln -s $G/functions/uvc.0/streaming/mjpeg/m $G/functions/uvc.0/streaming/header/h/m
sudo ln -s $G/functions/uvc.0/streaming/header/h $G/functions/uvc.0/streaming/class/fs
sudo ln -s $G/functions/uvc.0/streaming/header/h $G/functions/uvc.0/streaming/class/hs

sudo ln -s $G/functions/uvc.0/control/header/h $G/functions/uvc.0/control/class/fs

# --- 6. BIND TO CONFIGURATION ---
sudo mkdir -p $G/configs/c.1/strings/0x409
echo "UVC" | sudo tee $G/configs/c.1/strings/0x409/configuration > /dev/null
sudo ln -s $G/functions/uvc.0 $G/configs/c.1/uvc.0

# --- 7. BIND TO HARDWARE ---
# This finds the Pi 4 UDC (fe980000.usb) and tells it to turn on
ls /sys/class/udc | head -n1 | sudo tee $G/UDC > /dev/null

echo "UVC Hardware initialized. Check 'ls /dev/video*'"
