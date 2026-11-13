#!/bin/bash
# ============================================================================
#  T560 (20FJ) — збір даних із заліза для порту coreboot
#  Запускати НА T560 зі СТОКОВОЮ прошивкою, з live-Linux (Arch/Ubuntu — байдуже),
#  від root:   sudo bash collect_t560_hw.sh
#  Результат:  ./t560-hw-<дата>.tar.gz  — віддати мені.
# ============================================================================
set -u
if [ "$(id -u)" != "0" ]; then
    echo "!! Потрібен root:  sudo bash $0"
    echo "   (без root не буде pinctrl, ACPI, dmidecode, EDID — а вони найважливіші)"
    exit 1
fi
OUT="$(pwd)/t560-hw-$(date +%Y%m%d-%H%M)"
mkdir -p "$OUT"/{pinctrl,acpi,edid,hwmon}

echo ">> вивід у $OUT"

# --- debugfs (для pinctrl) -------------------------------------------------
mountpoint -q /sys/kernel/debug || mount -t debugfs none /sys/kernel/debug 2>/dev/null

# --- DMI / BIOS / EC версії ------------------------------------------------
dmidecode                > "$OUT/dmidecode.txt" 2>/dev/null
dmidecode -t 0,1,2,17    > "$OUT/dmidecode-mem.txt" 2>/dev/null
cat /sys/class/dmi/id/* 2>/dev/null | head -0
for f in /sys/class/dmi/id/*; do
    printf '%-24s %s\n' "$(basename "$f")" "$(cat "$f" 2>/dev/null)"
done                      > "$OUT/dmi-id.txt" 2>/dev/null

# --- PCI / USB -------------------------------------------------------------
lspci -nnvv               > "$OUT/lspci-vvv.txt" 2>/dev/null
lspci -tvnn               > "$OUT/lspci-tree.txt" 2>/dev/null
lsusb -tv                 > "$OUT/lsusb-tree.txt" 2>/dev/null
lsusb -v                  > "$OUT/lsusb-v.txt" 2>/dev/null

# --- ACPI ------------------------------------------------------------------
if command -v acpidump >/dev/null; then
    acpidump > "$OUT/acpi/acpi.txt" 2>/dev/null
    acpidump -b -o "$OUT/acpi/table.dump" >/dev/null 2>&1
fi
cp /sys/firmware/acpi/tables/* "$OUT/acpi/" 2>/dev/null
cp /sys/firmware/acpi/tables/dynamic/* "$OUT/acpi/" 2>/dev/null
command -v iasl >/dev/null && for t in DSDT SSDT*; do
    [ -f "$OUT/acpi/$t" ] && iasl -d -p "$OUT/acpi/$t" "$OUT/acpi/$t" >/dev/null 2>&1
done

# --- GPIO / pinctrl (НАЙВАЖЛИВІШЕ) ----------------------------------------
ls -l /sys/kernel/debug/pinctrl/ > "$OUT/pinctrl/dirs.txt" 2>/dev/null
for d in /sys/kernel/debug/pinctrl/*; do
    [ -d "$d" ] || continue
    n=$(basename "$d")
    cat "$d/pinconf-pins" > "$OUT/pinctrl/$n.pinconf" 2>/dev/null
    cat "$d/pinmux-pins"  > "$OUT/pinctrl/$n.pinmux"  2>/dev/null
    cat "$d/pins"         > "$OUT/pinctrl/$n.pins"    2>/dev/null
    cat "$d/gpio"         > "$OUT/pinctrl/$n.gpio"    2>/dev/null
done
command -v intel_pinconf >/dev/null && echo

# --- SMBus / i2c -----------------------------------------------------------
command -v i2cdetect >/dev/null && i2cdetect -l > "$OUT/i2c.txt" 2>/dev/null
for d in /sys/bus/i2c/devices/*; do
    printf '%-20s %s\n' "$(basename "$d")" "$(cat "$d/name" 2>/dev/null)"
done > "$OUT/i2c-devices.txt" 2>/dev/null

# --- дисплей / EDID --------------------------------------------------------
for e in /sys/class/drm/*/edid; do
    [ -s "$e" ] || continue
    cat "$e" > "$OUT/edid/$(basename "$(dirname "$e")").edid" 2>/dev/null
done
command -v edid-decode >/dev/null && for f in "$OUT"/edid/*.edid; do
    edid-decode "$f" > "$f.txt" 2>/dev/null
done

# --- аудіо -----------------------------------------------------------------
cat /proc/asound/cards  > "$OUT/asound-cards.txt" 2>/dev/null
cat /proc/asound/card*/codec* > "$OUT/hda-codecs.txt" 2>/dev/null

# --- живлення / вентилятор / LED ------------------------------------------
for d in /sys/class/power_supply/*; do
    [ -d "$d" ] || continue
    echo "== $(basename "$d")"; cat "$d"/uevent 2>/dev/null
done > "$OUT/power-supply.txt" 2>/dev/null
cat /sys/class/hwmon/hwmon*/name 2>/dev/null > "$OUT/hwmon/names.txt"
for d in /sys/class/hwmon/hwmon*; do
    cat "$d"/name 2>/dev/null | tr -d '\n' > "$OUT/hwmon/$(basename "$d").name"
    for f in "$d"/pwm* "$d"/fan*_input "$d"/temp*_input; do
        [ -f "$f" ] && printf '%-28s %s\n' "$(basename "$f")" "$(cat "$f" 2>/dev/null)"
    done > "$OUT/hwmon/$(basename "$d").values" 2>/dev/null
done
for d in /sys/class/leds/*; do
    printf '%-32s max=%s\n' "$(basename "$d")" "$(cat "$d/max_brightness" 2>/dev/null)"
done > "$OUT/leds.txt" 2>/dev/null

# --- ядро ------------------------------------------------------------------
dmesg > "$OUT/dmesg.txt" 2>/dev/null
uname -a > "$OUT/uname.txt"
cat /proc/cpuinfo > "$OUT/cpuinfo.txt"

# --- архів -----------------------------------------------------------------
if ! ls "$OUT"/pinctrl/*.pinconf >/dev/null 2>&1 || [ ! -s "$(ls "$OUT"/pinctrl/*.pinconf 2>/dev/null | head -1)" ]; then
    echo "!! pinctrl порожній."
    echo "   перевір:  mount -t debugfs none /sys/kernel/debug ; ls /sys/kernel/debug/pinctrl/"
    echo "   там має бути INT344B:00 (Sunrise Point-LP)."
fi
TAR="$(pwd)/$(basename "$OUT").tar.gz"
tar czf "$TAR" -C "$(dirname "$OUT")" "$(basename "$OUT")" 2>/dev/null
echo ">> готово: $TAR  ($(du -h "$TAR" | cut -f1))"
echo ">> сюди зокрема має бути непорожній pinctrl/INT344B:00.pinconf"
ls -l "$OUT/pinctrl/" 2>/dev/null
