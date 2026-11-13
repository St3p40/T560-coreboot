#!/usr/bin/env python3
"""
Генерує variants/t560/gpio.c з дампа `inteltool -g` (Sunrise Point-LP).

Значення DW0/DW1 переносяться дослівно, без інтерпретації в PAD_CFG_* —
тобто конфігурація падів буде рівно такою, як її виставила вендорська прошивка.

Використання:
    python gen_gpio_from_inteltool.py gpio-all.txt > variants/t560/gpio.c
"""
import re
import sys

LINE_RE = re.compile(r"^0x([0-9a-f]+):\s+0x([0-9a-f]{16})\s+(\S+)\s*(.*)$")
GROUP_RE = re.compile(r"^-+\s*GPIO Group (\S+)\s*-+$")
COMM_RE = re.compile(r"^-+\s*GPIO Community (\d+)\s*-+$")


def main(path):
    groups = []          # [(group_name, [(pad, dw0, dw1, mode)])]
    cur = None
    community = None

    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        m = COMM_RE.match(line.strip())
        if m:
            community = int(m.group(1))
            continue
        m = GROUP_RE.match(line.strip())
        if m:
            cur = (m.group(1), community, [])
            groups.append(cur)
            continue
        m = LINE_RE.match(line)
        if not m:
            continue
        value = int(m.group(2), 16)
        pad, mode = m.group(3), m.group(4).strip()
        if value == 0xFFFFFFFFFFFFFFFF:
            continue
        dw0 = value & 0xFFFFFFFF
        dw1 = (value >> 32) & 0xFFFFFFFF
        cur[2].append((pad, dw0, dw1, mode))

    out = []
    out.append("/* SPDX-License-Identifier: GPL-2.0-only */")
    out.append("")
    out.append("/*")
    out.append(" * ThinkPad T560 (20FJ): таблиця GPIO знята з живої машини зі стоковою")
    out.append(" * прошивкою (`inteltool -g`, Sunrise Point-LP).")
    out.append(" *")
    out.append(" * DW0/DW1 перенесені дослівно — це точна копія того, що виставив вендор,")
    out.append(" * без перекладу в PAD_CFG_* (переклад завжди несе ризик помилки).")
    out.append(" * Регенерація: tools/gen_gpio_from_inteltool.py gpio-all.txt")
    out.append(" */")
    out.append("")
    out.append("#include <soc/gpio.h>")
    out.append('#include "../../variant.h"')
    out.append("")
    out.append("#define PAD_CFG_RAW(pad, dw0, dw1)\t_PAD_CFG_STRUCT(pad, (dw0), (dw1))")
    out.append("")
    out.append("static const struct pad_config gpio_table[] = {")

    for name, comm, pads in groups:
        if not pads:
            continue
        label = "GPD" if name.startswith("GPD") else f"GPP_{name[-1]}"
        out.append("")
        out.append(f"\t/* ------- Community {comm} / GPIO Group {name} ------- */")
        for pad, dw0, dw1, mode in pads:
            comment = mode if mode and mode != "GPIO" else "GPIO"
            out.append(f"\tPAD_CFG_RAW({pad}, 0x{dw0:08x}, 0x{dw1:08x}),\t/* {comment} */")

    out.append("};")
    out.append("")
    out.append("void variant_config_gpios(void)")
    out.append("{")
    out.append("\tgpio_configure_pads(gpio_table, ARRAY_SIZE(gpio_table));")
    out.append("}")
    print("\n".join(out))


if __name__ == "__main__":
    import io
    src = sys.argv[1] if len(sys.argv) > 1 else "gpio-all.txt"
    dst = sys.argv[2] if len(sys.argv) > 2 else None
    buf = io.StringIO()
    old = sys.stdout
    sys.stdout = buf
    main(src)
    sys.stdout = old
    text = buf.getvalue()
    if dst:
        with open(dst, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    else:
        sys.stdout.write(text)
