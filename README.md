# Canon EOS exponálásszámláló kiolvasása macOS-en

Hogyan lehet USB-n kiolvasni egy Canon EOS fényképezőgép zárjának
exponálásszámát (shutter count) macOS-en, külön alkalmazás (pl. FreeShutterCounter)
nélkül, a nyílt forrású [gphoto2](http://gphoto.org/) segítségével.

Kipróbálva: **Canon EOS 70D** (firmware 1.1.2), macOS, Apple Silicon.
Eredmény 2026-11-05-én: **32 220** exponálás (a Canon 100 000-re méretezi a 70D zárját).

## Gyors használat

```bash
./shutter-count.sh --install   # első alkalommal: telepíti a gphoto2-t, ha hiányzik
./shutter-count.sh             # Gép: Canon EOS 70D / Exponálásszám: 32220
./shutter-count.sh --raw       # csak a szám, pl. naplózáshoz
```

## Kézi lépések

1. **gphoto2 telepítése**

   ```bash
   brew install gphoto2
   ```

2. **A gép csatlakoztatása:** USB-kábellel, bekapcsolva. A gép megjelenik
   a rendszerben (`system_profiler SPUSBDataType | grep -A3 Canon`, Canon vendor ID: `0x04a9`).

3. **Ellenőrzés, hogy a gphoto2 látja-e a gépet**

   ```bash
   gphoto2 --auto-detect
   # Canon EOS 70D                  usb:032,010
   ```

4. **A macOS kameraszolgáltatásának leállítása.** A `ptpcamerad` (és a
   `mscamerad-xpc`) automatikusan lefoglalja a csatlakoztatott gépet, ezért
   a gphoto2 ezt a hibát adja:

   ```
   Could not claim the USB device ... Make sure no other program (MacOS PTPCamera service) ...
   ```

   Megoldás: leállítani, közvetlenül a kiolvasás előtt (magától újraindul,
   ezért egy parancssorban kell futtatni):

   ```bash
   killall -9 ptpcamerad mscamerad-xpc; gphoto2 --get-config /main/status/shuttercounter
   ```

5. **Az eredmény**

   ```
   Label: Shutter Counter
   Readonly: 1
   Type: TEXT
   Current: 32220
   END
   ```

   A `Current` értéke az exponálásszám.

További hasznos parancs: `gphoto2 --summary` (géptípus, firmware, sorozatszám).

## Megjegyzések

- A szolgáltatás leállítása nem okoz kárt: a `ptpcamerad`-et a launchd azonnal
  újraindítja, a Fotók és a Digitális fényképek (Image Capture) utána is működik.
- Ha a script többször egymás után is „Could not claim” hibát kap, zárd be
  a Fotók, a Digitális fényképek vagy a Canon EOS Utility alkalmazást, ha fut.
- Nem minden Canon típus adja ki a számlálót PTP-n keresztül. Ha a
  `/main/status/shuttercounter` hiányzik, nézd meg:
  `gphoto2 --list-config | grep -i shutter`.
