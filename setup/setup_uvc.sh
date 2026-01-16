#!/bin/bash
set -e

G=/sys/kernel/config/usb_gadget/g1

# 1. CLEANUP (Strict unbind first)
if [ -d "$G" ]; then
    echo "Cleaning up..."
    echo "" | sudo tee $G/UDC || true
    sudo find $G/configs/c.1/ -maxdepth 1 -type l -delete || true
    sudo find $G -depth -type d -exec rmdir {} \; 2>/dev/null || true
fi

# 2. CREATE GADGET BASE
sudo mkdir -p $G && cd $G
echo 0x1d6b | sudo tee idVendor
echo 0x0104 | sudo tee idProduct
echo 0x0200 | sudo tee bcdUSB
# Essential for UVC
echo 0xef | sudo tee bDeviceClass
echo 0x02 | sudo tee bDeviceSubClass
echo 0x01 | sudo tee bDeviceProtocol

sudo mkdir -p strings/0x409
echo "1234567890" | sudo tee strings/0x409/serialnumber
echo "Raspberry Pi" | sudo tee strings/0x409/manufacturer
echo "Pi USB Webcam" | sudo tee strings/0x409/product

# 3. UVC FUNCTION (Step-by-Step Directory Creation)
# We avoid mkdir -p here to prevent "Operation not permitted"
sudo mkdir -p functions/uvc.usb0
sudo mkdir -p functions/uvc.usb0/streaming/mjpeg/m
# Now that 'm' exists, we create '720p' (cleaner name than f1)
sudo mkdir -p functions/uvc.usb0/streaming/mjpeg/m/720p

# 4. FRAME SETTINGS
cd functions/uvc.usb0/streaming/mjpeg/m/720p
echo 1280 | sudo tee wWidth
echo 720 | sudo tee wHeight
echo 1843200 | sudo tee dwMaxVideoFrameBufferSize
# Use 333333 for 30fps
echo "333333" | sudo tee dwFrameInterval
cd ../../../../..

# 5. HEADERS & LINKS (Required for Host to see the Format)
sudo mkdir -p functions/uvc.usb0/streaming/header/h
sudo ln -s functions/uvc.usb0/streaming/mjpeg/m functions/uvc.usb0/streaming/header/h/m
sudo ln -s functions/uvc.usb0/streaming/header/h functions/uvc.usb0/streaming/class/fs
sudo ln -s functions/uvc.usb0/streaming/header/h functions/uvc.usb0/streaming/class/hs

# Control Setup
sudo mkdir -p functions/uvc.usb0/control/header/h
sudo ln -s functions/uvc.usb0/control/header/h functions/uvc.usb0/control/class/fs

# 6. BIND TO CONFIGURATION
sudo mkdir -p configs/c.1/strings/0x409
echo "UVC" | sudo tee configs/c.1/strings/0x409/configuration
sudo ln -s functions/uvc.usb0 configs/c.1/

# 7. ENABLE (Bind to Pi 4 UDC)
ls /sys/class/udc | head -n1 | sudo tee $G/UDC
echo "UVC gadget is now ACTIVE."
