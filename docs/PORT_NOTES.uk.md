# T560 (20FJ) — порт coreboot: статус і план

## Готово

* `src/mainboard/lenovo/sklkbl_thinkpad/` — доданий варіант `t560`:
  * `Kconfig`: `BOARD_LENOVO_T560`, `SOC_INTEL_SKYLAKE`, `DIMM_SPD_SIZE=256` (DDR3L),
    без `HAVE_SPD_IN_CBFS` (SPD читаємо з SMBus у ромстейджі — працює з будь-якою планкою);
  * `Kconfig.name`, `MAINBOARD_PART_NUMBER="T560"`, `MAINBOARD_VERSION="ThinkPad T560"`;
  * `variants/t560/memory_init_params.c` — SPD 0x50/0x51 через SMBus;
  * `variants/t560/overridetree.cb` — xHCI / SATA / GBE / RP1 (кардридер RTS522A) / RP3 (WLAN);
  * `variants/t560/data.vbt` — **справжній VBT, витягнутий з вендорського `dump.bin`** (`$VBT` @ 0xde9914);
  * `variants/t560/gpio.c`, `hda_verb.c`, `gma-mainboard.ads` — поки копії з `t580` (див. «Здогадки»).
* ME/IFD/GBE для першого запису: `coreboot/binaries/{ifd.bin,me_deguarded.bin,gbe.bin}`
  (deguard-частина вже перевірена — BootGuard більше не гасить машину за 1 с).

## Збірка (перевірено)

* Toolchain: `util/crosscgg` → уточнення: `util/crossgcc` i386-elf-gcc 15.2.0, FSP `KabylakeFspBinPkg`, microcode `06-4e-03`.
* `build/coreboot.rom` → `T560_coreboot_deguarded.rom` (16 MiB).
  Актуальний образ: sha256 `5f4741de2456287f401b201cd07b6477798b021b9ec6c26ef9966b3dbc897561`,
  md5 `d2d946e930a41c75da508c227ca47161`.
* Перевірено: HAP=1 (`PCHSTRP0=0x00110000`), ME-регіон = `me_deguarded.bin` + 0xFF,
  GBE стоковий, FMAP `BIOS 0x700000/0x900000`, `COREBOOT 0x711000/0x8EF000`,
  `vbt.bin` = вендорський VBT, `cpu_microcode_blob.bin` на місці,
  `CONFIG_UNLOCK_FLASH_REGIONS=y` (внутрішня прошивка BIOS працюватиме).
* **Ще не для прошивки**: `gpio.c` — заглушка з `t580`.
## Дані про залізо (вже є)

| Що | Значення |
|---|---|
| Модель | 20FJS2RU00, ThinkPad T560, Skylake-U GT2 (8086:1916) |
| PCH | Sunrise Point-LP |
| BIOS / EC | `N1KET58W` / `N1KHT21W` |
| Пам'ять | DDR3L SO-DIMM, SPD `92 11 0b …` (2 слоти) |
| dGPU / TB3 | немає |
| PCIe | RP1 → RTS522A (кардридер), RP3 → MT7921 (WLAN), GBE I219-LM |
| VBT | витягнутий з вендорського дампа |

## Здогадки, які треба замінити реальними даними

1. **GPIO** — ✅ **зроблено по-справжньому.** `pinctrl` у Linux недоступний (Lenovo не
   експортує `INT344B` у ACPI), тому зняли регістри напряму: `inteltool -g` (залізо,
   `iomem=relaxed`) → `gpio-all.txt` → `tools/gen_gpio_from_inteltool.py` →
   `variants/t560/gpio.c`, 162 пади, DW0/DW1 **дослівно** як у вендора
   (через `_PAD_CFG_STRUCT`, без інтерпретації). Контроль: у DW1 біти 0-7 — це IRQ
   пада, і збігається з `GPP_*_IRQ` у coreboot (A0=0x18, B0=0x30, …) — значення
   коректні, не зсунуті.
2. **EC конфіг** (`config0..config3`, `eventX_enable` у `devicetree.cb`) — від `t580`.
3. **USB-карта** — зараз усі 10 USB2 / 4 USB3 портів увімкнені без OC-mapping
   (для першого старту це нормально, далі звузимо за `_UPC`/`_PLD` з вендорського ACPI).
4. **CLKREQ/CLKSRC для RP1/RP3, GBE** — взяті «за аналогією» (0/1/2).
5. **`DqPinsInterleaved=false`** — як у `t580` (15", 2 слоти). Якщо тренування
   пам'яті не пройде — перше, що міняємо, це `true`.
6. **HDA** — ✅ зроблено з `/proc/asound`: ALC293 (`0x10ec0293`/`0x17aa2231`) + SKL HDMI.

## Що потрібно з заліза (стокова прошивка + live Linux)

Запустити `collect_t560_hw.sh` на T560, віддати `t560-hw-*.tar.gz`. Звідти беремо:

* `pinctrl/*.pinconf` — **GPIO** (найважливіше);
* `acpi/*` — DSDT/SSDT: конфіг EC, `_UPC`/`_PLD` для USB, PCIe `_PRW`, кнопки, батарея;
* `lspci-vvv.txt`, `dmidecode*.txt`, `lsusb-tree.txt`, `dmesg.txt`;
* `edid/*` — панель (звірити з VBT);
* `hda-codecs.txt` — кодек і pin config для `hda_verb.c`.

## План

1. Зібрати образ (перевірка, що дерево і toolchain в порядку) — робиться.
2. Отримати `t560-hw-*.tar.gz`.
3. `intelp2m` → справжній `gpio.c`; за потреби поправити EC-конфіг і USB-карту.
4. Перевірка образу «на папері» (регіони, FMAP, SPD, відсутність заглушок).
5. Один зовнішній запис (`flashrom -p <prog> -w`), бажано з verify.
6. Якщо стартує — далі тільки `flashrom -p internal --ifd -i bios -N` з Linux-флешки.

## Bootsplash (лого)

* `variants/t560/bootsplash.jpg` — 1920x1072 (кратно 16, вписується у FHD 1920x1080),
  чорний фон, лого по центру, baseline JPEG 4:2:0, ~100 KiB.
* Конфіг: `CONFIG_BOOTSPLASH_IMAGE` + `CONFIG_BOOTSPLASH_FILE` + `CONFIG_BOOTSPLASH`
  + `CONFIG_GENERIC_LINEAR_FRAMEBUFFER` (без нього `LINEAR_FRAMEBUFFER` не вмикається,
  а `CONFIG_BOOTSPLASH` від нього залежить).
* У `Makefile.mk` прибрано суфікс `:jpg420` — він тягне ImageMagick на етапі збірки;
  зображення конвертуємо самі, вже у 4:2:0.
* Побічно знайдено й виправлено баг build-скрипта: CRLF→LF фільтр проходив і по бінарниках,
  через що `data.vbt` псувався (у CBFS було 3841 байт замість 3846). Тепер фільтр лише для
  текстових файлів, а `data.vbt`/`bootsplash.jpg` перевіряються за sha256 після синку.

## Фінал: UEFI (EDK2) — ПРАЦЮЄ

* Образ: `T560_coreboot_uefi.rom` (16 MiB), sha256
  `2926773a0dd18e3feae06f5e8ed51bc90b13604880f478384efb1d89b9dbdd1c`,
  md5 `189c4da95fd6b50d61b02139bfe4cebb`.
* Payload: **EDK2 UEFIPAYLOAD (MrChromebox)**, 2.1 MiB; **SMMSTORE** 512 KiB (`0x790000`);
  розкладка: `RW_MRC_CACHE 0x780000`, `SMMSTORE 0x790000`, `COREBOOT 0x811000–0x1000000`.
* Прошито внутрішньо (`flashrom -p internal --ifd -i bios -N -w`), verify OK,
  зчитування назад = образ байт-у-байт.
* Після прошивки: `dmidecode` → `CBET4000 t560-uefi`, EFI NVRAM 44 змінні (SMMSTORE живе),
  встановлена система завантажується з ESP через EDK2.

### Що перевірено на залізі (Apeiron, kernel 7.2.15)

* WiFi MT7921 (`mt7921e`): прошивка вантажиться, `wlan0`, скан і підключення працюють;
* Ethernet I219-LM (`e1000e`), кардридер RTS522A (`rtsx_pci`, 2.5 GT/s);
* звук ALC293 (`17aa:2231`) — динаміки, навушники, мікрофони, HDMI;
* клавіатура, Synaptics тачпад (PS/2), TrackPoint, лід, кнопки, Fn-клавіші (thinkpad_acpi);
* **батарея BAT0** видно, вентилятор `auto` (33 °C), сенсори thinkpad/pch/coretemp/mt7921;
* підсвітка `acpi_video0`; SATA SSD; USB (BT, камера, флешка, тетеринг).

### Залишкові дрібниці (косметика)

* `hpet_acpi_add: no address or irqs in _CRS` — попередження від HPET-пристрою в ACPI coreboot.
* ~10 correctable AER `RxErr` на кардридері під час ініціалізації лінку — далі тихо, лінк стабільний.
* TPM драйвер бачить як «1.2» — якщо колись знадобиться measured boot, розібратись окремо.
* USB-карта портів усе ще «широка» (усі 10/4 порти без OC-mapping) — звузити за `_UPC`/`_PLD`.
* EC `config0..3`/`eventX_enable` — від `t580`; працює, але можна звірити з вендорським ACPI.

## Фінальне полірування (прошито, перевірено)

Образ: `T560_coreboot_uefi.rom`, sha256
`b45a8b415628fa4320a3e0b9a8eebc4daee651495152cd5b3cdc11489d1da251`,
md5 `274cd53d9d7e6652028ec7d1b8fd1da4`.

* **Кардридер (RP1): AER вимкнено** → `PCIe Bus Error` у dmesg: **0** (раніше ~10 `RxErr`).
* **USB**: 12 портів USB2 + 6 USB3 (як у вендорському ACPI `HSP0..HSPB`/`SSP0..SSP5`);
  `xhci_hcd/12p` (480M) + `xhci_hcd/6p` (5000M). OC-mapping лишено `OC_SKIP`
  (розведені лише `GPP_E9/E10/E11`, відповідність «порт → OC» вендор не описав).
* Перевірено після прошивки: `CBET4000 t560-uefi`, fb0 **1920x1080**, EFI NVRAM 42 змінні,
  BAT0 100 % (`Not charging`), підсвітка, wifi `wlan0` у мережі.
* HPET: наш DSDT містить коректний `_CRS` (`Memory32Fixed(ReadWrite, 0xFED00000, 0x400)`) —
  попередження ядра, не наша ACPI.
* Для прошивки без pacman зібрано статичний `flashrom 1.4.0` (`tools/flashrom-static`);
  internal-программер вимагає libpci, тому збірка — зі статичним libpci.
