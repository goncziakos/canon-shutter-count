# Reading a Canon EOS shutter count on macOS

How to read the shutter count of a Canon EOS camera over USB on macOS,
without a dedicated app (such as FreeShutterCounter), using the open-source
[gphoto2](http://gphoto.org/).

Tested with: **Canon EOS 70D** (firmware 1.1.2), macOS, Apple Silicon.
Result on 2026-11-05: **32,220** shutter actuations (Canon rates the 70D shutter for 100,000).

## Quick start

```bash
./shutter-count.sh --install   # first run: installs gphoto2 if it is missing
./shutter-count.sh             # Camera: Canon EOS 70D / Shutter count: 32220
./shutter-count.sh --raw       # just the number, e.g. for logging
```

## Manual steps

1. **Install gphoto2**

   ```bash
   brew install gphoto2
   ```

2. **Connect the camera** with a USB cable and turn it on. It shows up in the
   system (`system_profiler SPUSBDataType | grep -A3 Canon`, Canon vendor ID: `0x04a9`).

3. **Check that gphoto2 sees the camera**

   ```bash
   gphoto2 --auto-detect
   # Canon EOS 70D                  usb:032,010
   ```

4. **Stop the macOS camera service.** `ptpcamerad` (and `mscamerad-xpc`)
   automatically claims any connected camera, so gphoto2 fails with:

   ```
   Could not claim the USB device ... Make sure no other program (MacOS PTPCamera service) ...
   ```

   Fix: kill it right before reading. It restarts on its own, so run both
   in a single command line:

   ```bash
   killall -9 ptpcamerad mscamerad-xpc; gphoto2 --get-config /main/status/shuttercounter
   ```

5. **The result**

   ```
   Label: Shutter Counter
   Readonly: 1
   Type: TEXT
   Current: 32220
   END
   ```

   The `Current` value is the shutter count.

Another useful command: `gphoto2 --summary` (model, firmware, serial number).

## Notes

- Killing the service is harmless: launchd restarts `ptpcamerad` immediately,
  and Photos and Image Capture keep working afterwards.
- If the script keeps getting "Could not claim" errors, quit Photos,
  Image Capture or Canon EOS Utility if any of them is running.
- Not every Canon model exposes the counter over PTP. If
  `/main/status/shuttercounter` is missing, check:
  `gphoto2 --list-config | grep -i shutter`.
