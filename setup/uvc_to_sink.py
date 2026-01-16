import numpy as np
import cv2
import socket
import time
from multiprocessing import shared_memory
import os

# --- CRITICAL FIX FOR SHARED MEMORY ---
# This prevents the resource tracker from killing the memory segment on exit
from multiprocessing import resource_tracker


def remove_shm_from_resource_tracker():
    def fix_register(name, rtype):
        if rtype == "shared_memory": return
        return resource_tracker._resource_tracker.register(name, rtype)
    resource_tracker.register = fix_register

    def fix_unregister(name, rtype):
        if rtype == "shared_memory": return
        return resource_tracker._resource_tracker.unregister(name, rtype)
    resource_tracker.unregister = fix_unregister


remove_shm_from_resource_tracker()


def find_uvc_gadget_node():
    for i in range(10):
        name_path = f"/sys/class/video4linux/video{i}/name"
        if os.path.exists(name_path):
            with open(name_path, "r") as f:
                if "UVC Gadget" in f.read():
                    return f"/dev/video{i}"
    return None


def run_uvc_sink():
    gadget_node = find_uvc_gadget_node()
    if not gadget_node:
        print("Error: UVC Gadget not found.")
        return

    # We use 1280x720 to match your Bash script's descriptor
    out = cv2.VideoWriter(
        gadget_node,
        cv2.CAP_V4L2,
        cv2.VideoWriter_fourcc(*'MJPG'),
        30,
        (1280, 720)
    )

    shm_name = "psm_raspininja_tahir2242"  # Ensure 'streamid' matches stream
    trigger_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    trigger_socket.bind(("127.0.0.1", 12345))

    shm = None
    try:
        # Wait for the producer to create the memory first
        while shm is None:
            try:
                shm = shared_memory.SharedMemory(name=shm_name)
            except FileNotFoundError:
                print("Waiting for Raspberry Ninja shared memory...")
                time.sleep(2)

        frame_buffer = np.ndarray(shm.size, dtype=np.uint8, buffer=shm.buf)
        last_frame = -1
        print(f"Streaming to {gadget_node}...")

        while True:
            trigger_socket.recv(1024)

            meta_header = frame_buffer[0:5]
            frame_num = meta_header[4]

            if frame_num == last_frame:
                continue

            width = int(meta_header[0]) * 255 + int(meta_header[1])
            height = int(meta_header[2]) * 255 + int(meta_header[3])

            if width == 0 or height == 0: continue

            # Extract frame data
            # NOTE: If publish.py is sending RAW frames, this works.
            # If it's sending encoded JPEGs, you'd need cv2.imdecode first.
            raw_data = frame_buffer[5:5+width*height*3]
            frame_array = raw_data.reshape((height, width, 3))

            # Resize ONLY if necessary (Resizing is heavy for the Pi Zero 2W)
            if width != 1280 or height != 720:
                frame_array = cv2.resize(frame_array, (1280, 720), interpolation=cv2.INTER_NEAREST)

            out.write(frame_array)
            last_frame = frame_num

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if out: out.release()
        if shm: shm.close()
        trigger_socket.close()


if __name__ == "__main__":
    try:
        run_uvc_sink()
    except KeyboardInterrupt:
        print("Stopping UVC sink.")
