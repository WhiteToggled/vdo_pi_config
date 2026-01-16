#!/usr/bin/env python3
import numpy as np
import cv2
from multiprocessing import shared_memory
from multiprocessing.resource_tracker import unregister
import time

# Shared memory from Raspberry Ninja
shm_name = "psm_raspininja_streamid"
shm = shared_memory.SharedMemory(name=shm_name)
frame_buffer = np.ndarray(shm.size, dtype=np.uint8, buffer=shm.buf)
unregister(shm._name, 'shared_memory')

# Open the UVC gadget device as MJPEG output
cap = cv2.VideoWriter(
    "/dev/video0",               # UVC gadget
    cv2.CAP_V4L2,
    cv2.VideoWriter_fourcc(*'MJPG'),
    30,                          # 30 fps
    (1280, 720)                  # 720p
)

last_frame = -1

try:
    while True:
        frame_data = frame_buffer.copy()
        meta_header = frame_data[0:5]
        frame_num = meta_header[4]

        if frame_num == last_frame:
            time.sleep(0.01)
            continue

        last_frame = frame_num
        width = int(meta_header[0])*255 + int(meta_header[1])
        height = int(meta_header[2])*255 + int(meta_header[3])

        if width == 0 or height == 0:
            continue

        frame_array = frame_data[5:5+width*height*3].reshape((height, width, 3))
        frame_resized = cv2.resize(frame_array, (1280, 720))
        cap.write(frame_resized)

except KeyboardInterrupt:
    pass
finally:
    cap.release()
    shm.close()

