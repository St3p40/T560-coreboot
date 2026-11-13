#!/bin/sh
# Build a coreboot image for ThinkPad T560 from this repo.
#
# Usage:  ./scripts/build.sh /path/to/coreboot [/path/to/output.rom]
#
# Assumes:
#   - coreboot tree has the T560 variant applied (patch/ or variant/ copied in)
#   - binaries/{ifd.bin,me_deguarded.bin,gbe.bin} exist (never committed)
#   - toolchain built (make crossgcc-i386) and submodules for FSP present
set -eu

COREBOOT=${1:?usage: build.sh /path/to/coreboot [output.rom]}
OUT=${2:-$COREBOOT/build/coreboot.rom}
HERE=$(cd "$(dirname "$0")/.." && pwd)

cd "$COREBOOT"

[ -f binaries/ifd.bin ]        || { echo "missing binaries/ifd.bin (with HAP bit set)"; exit 1; }
[ -f binaries/me_deguarded.bin ] || { echo "missing binaries/me_deguarded.bin"; exit 1; }
[ -f binaries/gbe.bin ]        || { echo "missing binaries/gbe.bin"; exit 1; }

if [ ! -d src/mainboard/lenovo/sklkbl_thinkpad/variants/t560 ]; then
    echo "T560 variant not present; apply patch/0001-*.patch first" >&2
    exit 1
fi

cp "$HERE/defconfig" .config
make olddefconfig
make -j"$(nproc)"

echo
echo "built: $(ls -l "$OUT" | awk '{print $5, $9}')"
sha256sum "$OUT"
