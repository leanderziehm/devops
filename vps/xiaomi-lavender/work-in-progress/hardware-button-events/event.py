#!/usr/bin/env python3
import glob
import select
from datetime import datetime
from evdev import InputDevice, ecodes

devices = {}

for path in sorted(glob.glob("/dev/input/event*")):
    try:
        dev = InputDevice(path)
        devices[dev.fd] = dev
        print(f"Monitoring {path}: {dev.name}")
    except (OSError, PermissionError) as e:
        print(f"Skipping {path}: {e}")

print("\nListening for input events. Press Ctrl+C to stop.\n")

try:
    while devices:
        ready, _, _ = select.select(
            list(devices.values()), [], []
        )

        for dev in ready:
            try:
                for event in dev.read():
                    timestamp = datetime.now().astimezone().isoformat(
                        timespec="milliseconds"
                    )

                    event_type = ecodes.EV.get(
                        event.type, str(event.type)
                    )

                    if event.type == ecodes.EV_KEY:
                        name = ecodes.KEY.get(
                            event.code, f"KEY_{event.code}"
                        )
                        state = {
                            0: "RELEASE",
                            1: "PRESS",
                            2: "REPEAT",
                        }.get(event.value, str(event.value))

                        print(
                            f"{timestamp} | {dev.path} | "
                            f"{dev.name} | {name} | {state}",
                            flush=True,
                        )
                    else:
                        code_name = ecodes.bytype.get(
                            event.type, {}
                        ).get(event.code, str(event.code))

                        print(
                            f"{timestamp} | {dev.path} | "
                            f"{dev.name} | {event_type} | "
                            f"{code_name} | value={event.value}",
                            flush=True,
                        )

            except OSError as e:
                print(f"Device disconnected: {dev.path}: {e}")
                devices.pop(dev.fd, None)

except KeyboardInterrupt:
    print("\nStopped.")

