module emulator_gameboy

import emulator_gameboy.mappers

[heap]
struct RAM {
mut:
	cartridge &mappers.GBMapper
	bios      &mappers.MapperNone
	bios_flag bool
	data      [0x10000]u8
}

pub fn (mut self RAM) read_byte(addr u16) u8 {
	// Cartridge memory
	if addr < 0x8000 || (addr >= 0xA000 && addr <= 0xBFFF) {
		if self.bios_flag {
			return self.bios.read_byte(addr)
		}
		return self.cartridge.read_byte(addr)
	}
	return self.data[addr]
}

pub fn (mut self RAM) read_word(addr u16) u16 {
	return u16(self.read_byte(addr + 1)) << 8 | self.read_byte(addr)
}

pub fn (mut self RAM) write_byte(addr u16, value u8) {
	// Cartridge memory
	if addr < 0x8000 || (addr >= 0xA000 && addr <= 0xBFFF) {
		if self.bios_flag {
			self.bios.write_byte(addr, value)
		}
		self.cartridge.write_byte(addr, value)
	}
	self.data[addr] = value
}

pub fn (mut self RAM) get_pointer(addr u16) &u8 {
	// Cartridge memory
	if addr < 0x8000 || (addr >= 0xA000 && addr <= 0xBFFF) {
		if self.bios_flag {
			return self.bios.get_pointer(addr)
		}
		return self.cartridge.get_pointer(addr)
	}
	return &self.data[addr]
}

pub fn (mut self RAM) write_word(addr u16, val u16) {
	self.write_byte(addr + 1, u8(val >> 8))
	self.write_byte(addr, u8(val & 0xFF))
}
