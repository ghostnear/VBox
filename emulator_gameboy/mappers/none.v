module mappers

pub struct MapperNone {
	name string = 'None'
mut:
	data [0x8000]u8
}

pub fn (mut self MapperNone) set_rom_data(data []u8) {
	if data.len > 0x8000 {
		panic('Gameboy ROM file is too big!')
	}
	for index in 0 .. data.len {
		self.data[index] = data[index]
	}
}

pub fn (mut self MapperNone) read_byte(addr u16) u8 {
	return self.data[addr]
}

pub fn (mut self MapperNone) write_byte(addr u16, value u8) {
	self.data[addr] = value
}

pub fn (mut self MapperNone) read_word(addr u16) u16 {
	return u16(self.read_byte(addr)) << 8 | self.read_byte(addr + 1)
}

pub fn (mut self MapperNone) write_word(addr u16, value u16) {
	self.write_byte(addr, u8(value >> 8))
	self.write_byte(addr + 1, u8(value & 0xFF))
}

pub fn (mut self MapperNone) get_pointer(addr u16) &u8 {
	return &self.data[addr]
}
