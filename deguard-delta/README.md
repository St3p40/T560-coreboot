# deguard delta — ThinkPad T560 (20FJ)

Delta data for [deguard](https://review.coreboot.org/deguard), generated from a
factory (vendor) firmware dump of this board with:

```sh
python generatedelta.py --input factory_dump.bin --output data/delta/thinkpad_t560
rm -rf data/delta/thinkpad_t560/home/secureboot     # required for the zero-FPF config
rm -rf data/delta/thinkpad_t560/home/{amt,fwupdate,pavp}   # optional, kept out
```

Use it to build the BootGuard-bypassing ME image:

```sh
./finalimage.py \
    --delta data/delta/thinkpad_t560 \
    --version 11.6.0.1126 \
    --pch LP --sku 2M \
    --fake-fpfs data/fpfs/zero \
    --input me_donor.bin \
    --output me_deguarded.bin
```

Donor: Dell Inspiron 5468 BIOS 1.3.0, extracted with `Dell_PFS_Extract.py`
(`me_donor.bin`, 0x1f0000 bytes, sha256
`912271bb3ff2cf0e2e27ccfb94337baaca027e6c90b4245f9807a592c8a652e1` — the same one
listed in coreboot's `Documentation/mainboard/lenovo/skylake.md`).

Remember to set the **HAP bit** in the flash descriptor afterwards
(`ifdtool -p sklkbl -M 1 ifd.bin`), otherwise the ME never stops and the machine
will not boot.

If you want this board supported by deguard out of the box, consider submitting
this directory to the deguard repository via Gerrit.
