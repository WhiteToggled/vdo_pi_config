#!/bin/bash
set -e

G=/sys/kernel/config/usb_gadget/g1

# Clean up any existing gadget
if [ -d "$G" ]; then
  echo "" > $G/UDC || true
  rm -rf $G
fi

mkdir -p $G
cd $G

# USB IDs (Linux Foundation demo VID, fine for testing)
echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# Device strings
mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "Raspberry Pi" > strings/0x409/manufacturer
echo "Pi USB Webcam" > strings/0x409/product

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "UVC Webcam" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# -------------------------
# UVC FUNCTION (VIDEO ONLY)
# -------------------------

mkdir -p functions/uvc.usb0

# ---- Control interface ----
mkdir -p functions/uvc.usb0/control/header/h
ln -s functions/uvc.usb0/control/header/h functions/uvc.usb0/control/class/fs
ln -s functions/uvc.usb0/control/header/h functions/uvc.usb0/control/class/ss

# ---- Streaming interface ----
mkdir -p functions/uvc.usb0/streaming/uncompressed/u
mkdir -p functions/uvc.usb0/streaming/uncompressed/u/frame/f1

# 720p @ 30fps
echo 1280 > functions/uvc.usb0/streaming/uncompressed/u/frame/f1/wWidth
echo 720  > functions/uvc.usb0/streaming/uncompressed/u/frame/f1/wHeight
echo 333333 > functions/uvc.usb0/streaming/uncompressed/u/frame/f1/dwFrameInterval

# Streaming headers
mkdir -p functions/uvc.usb0/streaming/header/h
ln -s functions/uvc.usb0/streaming/uncompressed/u \
      functions/uvc.usb0/streaming/header/h/u
ln -s functions/uvc.usb0/streaming/header/h \
      functions/uvc.usb0/streaming/class/fs
ln -s functions/uvc.usb0/streaming/header/h \
      functions/uvc.usb0/streaming/class/ss

# Attach function to configuration
ln -s functions/uvc.usb0 configs/c.1/

# Enable gadget
echo "$(ls /sys/class/udc)" > UDC
