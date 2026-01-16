#!/bin/bash
# No 'set -e' for the cleanup part to ensure it wipes everything
G=/sys/kernel/config/usb_gadget/g1

echo "Wiping old configuration..."
echo "" > $G/UDC 2>/dev/null || true
find $G -type l -delete 2>/dev/null || true
find $G -depth -type d -exec rmdir {} \; 2>/dev/null || true

set -e # Stop if any creation step fails
echo "Creating Gadget..."
mkdir -p $G
echo 0x1d6b > $G/idVendor
echo 0x0104 > $G/idProduct
echo 0x0200 > $G/bcdUSB
echo 0xef > $G/bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

mkdir -p $G/strings/0x409
echo "1234567890" > $G/strings/0x409/serialnumber
echo "Raspberry Pi" > $G/strings/0x409/manufacturer
echo "Pi USB Webcam" > $G/strings/0x409/product

echo "Creating UVC Function..."
# Create the function folder first
mkdir -p $G/functions/uvc.0

# Define the stream format and frame (MJPEG 720p)
mkdir -p $G/functions/uvc.0/streaming/mjpeg/m/f1
echo 1280 > $G/functions/uvc.0/streaming/mjpeg/m/f1/wWidth
echo 720 > $G/functions/uvc.0/streaming/mjpeg/m/f1/wHeight
echo 333333 > $G/functions/uvc.0/streaming/mjpeg/m/f1/dwFrameInterval

# Link headers (Essential for the OS to recognize the camera)
mkdir -p $G/functions/uvc.0/streaming/header/h
ln -s $G/functions/uvc.0/streaming/mjpeg/m $G/functions/uvc.0/streaming/header/h/m
ln -s $G/functions/uvc.0/streaming/header/h $G/functions/uvc.0/streaming/class/fs
ln -s $G/functions/uvc.0/streaming/header/h $G/functions/uvc.0/streaming/class/hs

mkdir -p $G/functions/uvc.0/control/header/h
ln -s $G/functions/uvc.0/control/header/h $G/functions/uvc.0/control/class/fs

# Bind to configuration
mkdir -p $G/configs/c.1/strings/0x409
echo "UVC" > $G/configs/c.1/strings/0x409/configuration
ln -s $G/functions/uvc.0 $G/configs/c.1/uvc.0

# Final Activation
echo "Binding to UDC..."
ls /sys/class/udc > $G/UDC
echo "Done! Check ls /dev/video*"
