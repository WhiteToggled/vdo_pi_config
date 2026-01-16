#!/bin/bash
set -e

G=/sys/kernel/config/usb_gadget/g1

# ---------------------------
# CLEANUP EXISTING GADGET
# ---------------------------
if [ -d "$G" ]; then
    echo "Cleaning up..."
    echo "" | sudo tee $G/UDC || true
    sudo find $G -type l -delete
    sudo find $G -depth -type d -exec rmdir {} \; 2>/dev/null || true
fi

# ---------------------------
# CREATE NEW GADGET
# ---------------------------
echo "Creating new gadget..."
sudo mkdir -p $G
cd $G

# USB IDs (Linux Foundation VID for testing)
echo 0x1d6b | sudo tee idVendor
echo 0x0104 | sudo tee idProduct
echo 0x0100 | sudo tee bcdDevice
echo 0x0200 | sudo tee bcdUSB

# ---------------------------
# DEVICE STRINGS
# ---------------------------
sudo mkdir -p strings/0x409
echo "1234567890" | sudo tee strings/0x409/serialnumber
echo "Raspberry Pi" | sudo tee strings/0x409/manufacturer
echo "Pi USB Webcam" | sudo tee strings/0x409/product

# ---------------------------
# CONFIGURATION
# ---------------------------
sudo mkdir -p configs/c.1/strings/0x409
echo "UVC Webcam" | sudo tee configs/c.1/strings/0x409/configuration

# ---------------------------
# UVC FUNCTION (VIDEO ONLY)
# ---------------------------
sudo mkdir -p functions/uvc.usb0

U=functions/uvc.usb0/streaming/uncompressed/u
F=$U/frame/f1

# Define 720p 30fps
sudo mkdir -p $F
echo 1280 | sudo tee $F/wWidth
echo 720  | sudo tee $F/wHeight
echo 1843200 | sudo tee $F/dwMaxVideoFrameBufferSize # (1280*720*2)
cat <<EOF | sudo tee $F/dwFrameInterval
333333
EOF

# Color Matching (Crucial for Windows/macOS)
sudo mkdir -p $U/../../color_matching/default

# Streaming Headers & Symlinks
sudo mkdir -p functions/uvc.usb0/streaming/header/h
sudo ln -s $U functions/uvc.usb0/streaming/header/h/u
sudo ln -s functions/uvc.usb0/streaming/header/h functions/uvc.usb0/streaming/class/fs
sudo ln -s functions/uvc.usb0/streaming/header/h functions/uvc.usb0/streaming/class/hs
sudo ln -s functions/uvc.usb0/streaming/header/h functions/uvc.usb0/streaming/class/ss

# Control Headers & Symlinks
sudo mkdir -p functions/uvc.usb0/control/header/h
sudo ln -s functions/uvc.usb0/control/header/h functions/uvc.usb0/control/class/fs
sudo ln -s functions/uvc.usb0/control/header/h functions/uvc.usb0/control/class/ss

# Bind
sudo ln -s functions/uvc.usb0 configs/c.1/
ls /sys/class/udc | head -n1 | sudo tee $G/UDC
echo "UVC gadget active."
