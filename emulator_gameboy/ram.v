module emulator_gameboy

import emulator_gameboy.mappers

[heap]
struct RAM {
mut:
	cartridge &mappers.Mapper
	bios      &mappers.MapperNone
	bios_flag bool
	ppu       &PPU

	wram [0x2000]u8
	hram [0x100]u8
}

pub fn (mut self RAM) read_byte(addr u16) u8 {
	// Cartridge memory + External RAM (if any)
	if addr <= 0x7FFF || (addr >= 0xA000 && addr <= 0xBFFF) {
		if self.bios_flag {
			return self.bios.read_byte(addr)
		}
		return self.cartridge.read_byte(addr)
	}

	// VRAM
	if addr <= 0x9FFF && addr >= 0x8000 {
		return self.ppu.read_vram_byte(addr - 0x8000)
	}

	// WRAM
	if addr >= 0xC000 && addr <= 0xDFFF {
		return self.wram[addr - 0xC000]
	}

	// ECHO RAM
	if addr >= 0xE000 && addr <= 0xFDFF {
		return self.read_byte(addr - 0x2000)
	}

	// OAM
	if addr >= 0xFE00 && addr <= 0xFE9F {
		return self.ppu.read_oam_byte(addr - 0xFE00)
	}

	// High RAM
	if addr >= 0xFF00 {
		if addr >= 0xFF40 && addr <= 0xFF4B {
			return self.ppu.read_lcdc_byte(addr - 0xFF40)
		}

		return self.hram[addr - 0xFF00]
	}

	return 0xFF
}

pub fn (mut self RAM) read_word(addr u16) u16 {
	return u16(self.read_byte(addr + 1)) << 8 | self.read_byte(addr)
}

pub fn (mut self RAM) write_byte(addr u16, value u8) {
	// Cartridge memory + External RAM (if any)
	if addr < 0x8000 || (addr >= 0xA000 && addr <= 0xBFFF) {
		if self.bios_flag && addr <= 0xFF {
			self.bios.write_byte(addr, value)
		}
		self.cartridge.write_byte(addr, value)
		return
	}

	// VRAM
	if addr <= 0x9FFF && addr >= 0x8000 {
		self.ppu.write_vram_byte(addr - 0x8000, value)
		return
	}

	// WRAM
	if addr >= 0xC000 && addr <= 0xDFFF {
		self.wram[addr - 0xC000] = value
		return
	}

	// OAM
	if addr >= 0xFE00 && addr <= 0xFE9F {
		self.ppu.write_oam_byte(addr - 0xFE00, value)
		return
	}

	// ECHO RAM
	if addr >= 0xE000 && addr <= 0xFDFF {
		self.write_byte(addr - 0x2000, value)
		return
	}

	// High RAM
	if addr >= 0xFF00 {
		if addr >= 0xFF40 && addr <= 0xFF4B {
			self.ppu.write_lcdc_byte(addr - 0xFF40, value)
		}

		self.hram[addr - 0xFF00] = value
	}
}

// This gets the pointer to the adress of the value we are writing to. It's useful mostly for simplifying CPU instructions.
pub fn (mut self RAM) get_pointer(addr u16) &u8 {
	// Cartridge memory + External RAM (if any)
	if addr < 0x8000 || (addr >= 0xA000 && addr <= 0xBFFF) {
		if self.bios_flag && addr <= 0xFF {
			return self.bios.get_pointer(addr)
		}
		return self.cartridge.get_pointer(addr)
	}

	// VRAM
	if addr <= 0x9FFF && addr >= 0x8000 {
		return self.ppu.get_vram_pointer(addr - 0x8000)
	}

	// WRAM
	if addr >= 0xC000 && addr <= 0xDFFF {
		return &self.wram[addr - 0xC000]
	}

	// OAM
	if addr >= 0xFE00 && addr <= 0xFE9F {
		return self.ppu.get_oam_pointer(addr - 0xFE00)
	}

	// ECHO RAM
	if addr >= 0xE000 && addr <= 0xFDFF {
		return &self.wram[addr - 0xE000]
	}

	// High RAM
	if addr >= 0xFF00 {
		if addr >= 0xFF40 && addr <= 0xFF4B {
			return self.ppu.get_lcdc_pointer(addr - 0xFF40)
		}

		return &self.hram[addr - 0xFF00]
	}

	return unsafe { nil }
}

pub fn (mut self RAM) write_word(addr u16, val u16) {
	self.write_byte(addr + 1, u8(val >> 8))
	self.write_byte(addr, u8(val & 0xFF))
}
