#!/bin/bash

# 1. Start Raspberry Ninja (The Producer)
# Replace 'tahir2242' with your actual stream ID
python3 /home/pi/raspberry_ninja/publish.py --framebuffer tahir2242 --h264 --noaudio --lowlatency &

# 2. Wait a few seconds for the shared memory to be created
sleep 3

# 3. Start your Sink Script (The Consumer)
python3 /home/pi/uvc_to_sink.py &

# Wait for background processes
wait -n
exit $?
