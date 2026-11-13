/* SPDX-License-Identifier: GPL-2.0-only */

/*
 * ThinkPad T560 (20FJ): Realtek ALC293 (0x10ec0293, subsystem 0x17aa2231),
 * + Intel Skylake HDMI (0x80862809).
 *
 * Значення pin default узято з живого /proc/asound/card0/codec#0 цієї машини.
 * Формат заголовка: vendor/device, subsystem, кількість груп по 4 dword
 * (1 група = subvendor або один pin).
 */

#include <device/azalia_device.h>

const u32 cim_verb_data[] = {
	0x10ec0293, // Vendor/Device ID: Realtek ALC293
	0x17aa2231, // Subsystem ID
	12,         // 1 (subvendor) + 11 pins

	AZALIA_SUBVENDOR(0, 0x17aa2231),

	AZALIA_PIN_CFG(0, 0x12, 0x90a60130), // [Fixed] Mic at Int N/A
	AZALIA_PIN_CFG(0, 0x13, 0x40000000), // does not describe a jack or internal device
	AZALIA_PIN_CFG(0, 0x14, 0x90170110), // [Fixed] Speaker at Int N/A
	AZALIA_PIN_CFG(0, 0x15, 0x03211040), // [Jack] HP Out at Ext Left
	AZALIA_PIN_CFG(0, 0x16, 0x411111f0), // [N/A] Speaker at Ext Rear
	AZALIA_PIN_CFG(0, 0x18, 0x411111f0), // [N/A] Speaker at Ext Rear
	AZALIA_PIN_CFG(0, 0x19, 0x411111f0), // [N/A] Speaker at Ext Rear
	AZALIA_PIN_CFG(0, 0x1a, 0x03a11020), // [Jack] Mic at Ext Left
	AZALIA_PIN_CFG(0, 0x1b, 0x411111f0), // [N/A] Speaker at Ext Rear
	AZALIA_PIN_CFG(0, 0x1d, 0x40738105), // [N/A] Modem Hand at Ext N/A
	AZALIA_PIN_CFG(0, 0x1e, 0x411111f0), // [N/A] Speaker at Ext Rear

	0x80862809, // Vendor/Device ID: Intel Skylake HDMI
	0x80860101, // Subsystem ID
	4,          // 1 (subvendor) + 3 pins

	AZALIA_SUBVENDOR(2, 0x80860101),

	AZALIA_PIN_CFG(2, 0x05, 0x18560010), // [Jack] Digital Out at Int HDMI
	AZALIA_PIN_CFG(2, 0x06, 0x18560010),
	AZALIA_PIN_CFG(2, 0x07, 0x18560010),
};

const u32 pc_beep_verbs[] = {};
AZALIA_ARRAY_SIZES;
