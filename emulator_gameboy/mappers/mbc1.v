module mappers

pub struct MapperMBC1 {
	name string = 'MBC1'
mut:
	banks    [][0x4000]u8
	rom_bank u8 = 1
}

// TODO: implement RAM?

pub fn (mut self MapperMBC1) load_rom_bytes(data []u8) {
	// 2 Megabyte max filesize
	if data.len > 0x200000 {
		panic('ERROR: Gameboy ROM file is too big!')
	}

	unsafe {
		self.banks.grow_len(data.len / 0x4000)
	}

	// TODO: surely V has a better way of copying than this...
	for index in 0 .. data.len {
		self.banks[index / 0x4000][index % 0x4000] = data[index]
	}
}

[inline]
pub fn (mut self MapperMBC1) read_byte(addr u16) u8 {
	// First bank, forced.
	if addr <= 0x3FFF {
		return self.banks[0][addr]
	}

	// Any other banks
	if addr <= 0x7FFF {
		return self.banks[self.rom_bank][addr - 0x4000]
	}

	// No RAM, no nothing, just 0x00.
	return 0x00
}

[inline]
pub fn (mut self MapperMBC1) write_byte(addr u16, value u8) {
	// ROM bank number
	if addr >= 0x2000 && addr <= 0x3FFF {
		self.rom_bank = value & 0b11111
	}
}

[inline]
pub fn (mut self MapperMBC1) read_word(addr u16) u16 {
	return u16(self.read_byte(addr)) << 8 | self.read_byte(addr + 1)
}

[inline]
pub fn (mut self MapperMBC1) write_word(addr u16, value u16) {
	self.write_byte(addr, u8(value >> 8))
	self.write_byte(addr + 1, u8(value & 0xFF))
}

pub fn (mut self MapperMBC1) get_pointer(addr u16) &u8 {
	// First bank, forced.
	if addr <= 0x3FFF {
		return &self.banks[0][addr]
	}

	// Any other banks
	if addr <= 0x7FFF {
		return &self.banks[self.rom_bank][addr - 0x4000]
	}

	// No RAM, no nothing, just 0x00.
	return 0x00
}
