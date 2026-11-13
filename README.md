# coreboot for Lenovo ThinkPad T560 (20FJ)

Coreboot port for the **ThinkPad T560** (Skylake-U, 15", 2016), with Intel ME
"deguarded" (BootGuard bypassed) and an EDK2/UEFI payload.

Tested on: **20FJS2RU00**, i5-6300U, 2×8 GB DDR3L-1600, FHD panel.

## Status

| Feature | State |
|---|---|
| Boot (coreboot → EDK2 → Linux/Windows) | ✅ works |
| Memory (2× DDR3L SO-DIMM, SPD over SMBus) | ✅ 16 GB trained |
| Graphics (libgfxinit, eDP 1920×1080) | ✅ |
| UEFI variables (SMMSTORE) | ✅ |
| SATA (2.5", AHCI) | ✅ |
| USB (12 × USB2, 6 × USB3) | ✅ |
| WiFi (MT7921), BT, camera | ✅ |
| Ethernet (I219-LM) | ✅ (driver binds; no cable tested) |
| Card reader (RTS522A) | ✅ |
| Audio (ALC293 + HDMI) | ✅ |
| Keyboard, touchpad (PS/2), TrackPoint, Fn keys | ✅ |
| EC (`thinkpad_acpi`): battery, fan, brightness | ✅ |
| Suspend | not tested |
| TPM | visible, but chip answers as TPM 1.2 |
| dGPU / Thunderbolt | not present on this model |

## Hardware notes

* **Skylake-U + DDR3L**: upstream `lenovo/sklkbl_thinkpad` only carries Kaby Lake
  (DDR4) variants. This variant selects `SOC_INTEL_SKYLAKE` and
  `DIMM_SPD_SIZE=256`, and reads SPD from SMBus at runtime instead of shipping
  `spd.bin` in CBFS — so any DDR3L module works.
* **VBT** is the vendor one, extracted from a stock flash dump (`$VBT` signature),
  so panel timings match the real machine (`LG LP156WF6-SPK3`).
* **GPIO** table is a verbatim copy of the vendor configuration: read with
  `inteltool -g` from the running stock firmware (`iomem=relaxed` required),
  then converted 1:1 into `_PAD_CFG_STRUCT()` entries. Lenovo does not expose the
  Sunrise Point-LP GPIO controller in ACPI (no `INT344B`), so Linux `pinctrl`
  debugfs is not usable on this machine.
* **PCIe CLKREQ is disabled** on RP1/RP3/GBE: the exact CLKREQ# wiring is unknown
  and a wrong number loses the reference clock on L1 entry (symptom: WiFi
  `Timeout for driver own`, `Unable to change power state from D3cold to D0`).
* **HDA** verbs are generated from the live `/proc/asound` codec dump (ALC293,
  subsystem `17aa:2231`).

## Firmware requirements: ME / BootGuard

This machine has BootGuard fused. A plain coreboot image will power off after
~1 second. You need:

1. A **deguarded ME image** (`11.6.0.1126`, LP, 2M donor) — see
   <https://review.coreboot.org/deguard> and `Documentation/soc/intel/deguard.md`.
   The delta for this board is in `deguard-delta/thinkpad_t560/`.
2. The **HAP bit set** in the flash descriptor (`ifdtool -p sklkbl -M 1`), otherwise
   the ME never stops and the platform does not boot.

Note that with HAP the ME is halted: no AMT/vPro, and the ME version is not reported.

## Building

Requirements: Linux build host, coreboot toolchain (`make crossgcc-i386`),
the FSP binaries and Intel microcode submodules, EDK2 payload sources.

```sh
# 1. coreboot at the tested commit
git clone https://review.coreboot.org/coreboot
cd coreboot
git checkout a1798a611a8fe58c2808fcbe9162cab5853f9d4e
git submodule update --init 3rdparty/fsp 3rdparty/blobs 3rdparty/libgfxinit
# 3rdparty/intel-microcode is 'update = none'; clone it manually and check out
# the pinned commit (Skylake-U microcode lives in intel-ucode/06-4e-03)

# 2. apply the port
git apply /path/to/patch/0001-sklkbl_thinkpad-add-ThinkPad-T560-variant.patch
# (or copy variant/* into src/mainboard/lenovo/sklkbl_thinkpad/variants/t560/
#  and add the Kconfig/Kconfig.name hunks by hand)

# 3. binaries: ifd.bin with HAP set, me_deguarded.bin, gbe.bin from your own dump
mkdir -p binaries        # never commit these

# 4. build
cp /path/to/defconfig .config
make olddefconfig
make -j$(nproc)
```

`build/coreboot.rom` is a full 16 MiB image (IFD + GBE + ME + BIOS).

### Bootsplash (optional)

No splash is shipped in this repository. If you want one, set
`CONFIG_BOOTSPLASH_IMAGE=y`, `CONFIG_BOOTSPLASH_FILE="<path to your.jpg>"` and
`CONFIG_BOOTSPLASH=y` (plus `CONFIG_GENERIC_LINEAR_FRAMEBUFFER=y`, which
`CONFIG_BOOTSPLASH` depends on).

Constraints: JPEG, image ≤ framebuffer size, width/height multiples of 16.
Upstream coreboot converts the file with ImageMagick (`:jpg420` suffix in
`Makefile.mk`); if you pre-convert to baseline 4:2:0 yourself you can drop that
suffix. Example that worked on this machine: 1920×1072, black background,
~100 KiB.

## Flashing

First flash **must** be external (the ME region cannot be written internally):

```sh
flashrom -p <programmer> -w coreboot.rom
flashrom -p <programmer> -v coreboot.rom      # verify
```

Later updates only touch the BIOS region and can be done from a running system:

```sh
flashrom -p internal --ifd -i bios -N -w coreboot.rom
```

## Known limitations

* TPM is reported as 1.2 (the chip was configured that way by the vendor
  firmware); measured boot is not set up.
* USB port mapping uses `OC_SKIP` for all ports: the OC pins exist
  (`GPP_E9/E10/E11`) but per-port mapping is not described by the vendor ACPI.
* EC configuration bytes (`config0..3`, `eventX_enable`) are inherited from the
  T580 variant. Everything tested works; comparing them against the vendor ACPI
  would be the next step.
* No OC/overclocking, no dGPU, no TB3 (not present on this model).

## Repository layout

```
variant/                 files for src/mainboard/lenovo/sklkbl_thinkpad/variants/t560/
patch/                   git-am-able patch against coreboot a1798a611a8f
defconfig                the exact build configuration used
deguard-delta/           ME delta for deguard (submit upstream if you like)
scripts/                 build helper, GPIO converter, hardware data collector
docs/                    technical notes (uk) + raw vendor GPIO dump
```

## License

GPL-2.0-only, same as coreboot. See `LICENSE`.

The vendor-derived blobs (VBT, bootsplash JPEG) come from the author's own
machine / own artwork.
