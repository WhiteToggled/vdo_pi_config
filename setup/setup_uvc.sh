# /boot/config.txt
# dtoverlay=dw2
#
# /boot/cmdline.txt
# modules-load=dwc2
#
# *g_webcam

# install uvc-gadget (x)
# sudo apt update
# sudo apt install -y git build-essential cmake pkg-config libusb-1.0-0-dev libsystemd-dev
# git clone https://github.com/wlhe/uvc-gadget.git /opt/uvc-gadget
# cd /opt/uvc-gadget

#!/bin/bash
# Pi UVC gadget setup 720p

G=/sys/kernel/config/usb_gadget/g1
mkdir -p $G
cd $G

# Device IDs
echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# Strings
mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "Raspberry Pi" > strings/0x409/manufacturer
echo "Pi USB Webcam" > strings/0x409/product

# Config
mkdir -p configs/c.1/strings/0x409
echo "UVC Config" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# UVC function (video 720p)
mkdir -p functions/uvc.usb0
echo 1280 > functions/uvc.usb0/streaming_maximum_width
echo 720  > functions/uvc.usb0/streaming_maximum_height
echo 333333 > functions/uvc.usb0/streaming_maximum_frame_interval  # 30fps in 100ns units

ln -s functions/uvc.usb0 configs/c.1/

# Bind to UDC (make the gadget live)
echo "$(ls /sys/class/udc)" > UDC

# ---- 2. Start Raspberry Ninja ----
cd /home/pi/raspberry_ninja
/usr/bin/python3 publish.py --rpi --video-pipeline "videoconvert ! appsink" --noaudio --lowlatency

