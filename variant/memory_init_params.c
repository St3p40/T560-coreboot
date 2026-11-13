/* SPDX-License-Identifier: GPL-2.0-only */

#include <soc/romstage.h>
#include <spd_bin.h>
#include <stdint.h>

/*
 * ThinkPad T560 (20FJ): Skylake-U, два слоти DDR3L SO-DIMM (SPD 256 байт,
 * CONFIG_DIMM_SPD_SIZE=256). SPD читаємо з SMBus під час ромстейджу,
 * у CBFS його не тримаємо — тоді працює будь-яка DDR3L-планка.
 */
void mainboard_memory_init_params(FSPM_UPD *mupd)
{
	FSP_M_CONFIG *mem_cfg = &mupd->FspmConfig;

	struct spd_block blk = { .addr_map = { 0x50, 0x51, } };
	get_spd_smbus(&blk);
	dump_spd_info(&blk);

	mem_cfg->MemorySpdDataLen  = CONFIG_DIMM_SPD_SIZE;

	/*
	 * 15" T5xx: DQ не інтерлівиться між каналами (як у t580).
	 * Якщо тренування пам'яті не пройде — перше, що варто спробувати,
	 * це поміняти на true.
	 */
	mem_cfg->DqPinsInterleaved = false;

	/* Канал A / канал B; порожній слот -> NULL, FSP такий канал пропускає. */
	mem_cfg->MemorySpdPtr00 = blk.spd_array[0][0] ? (uintptr_t)blk.spd_array[0] : 0;
	mem_cfg->MemorySpdPtr10 = blk.spd_array[1][0] ? (uintptr_t)blk.spd_array[1] : 0;
}
