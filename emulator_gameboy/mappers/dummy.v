module mappers

pub struct MapperDummy {
	name string = 'Dummy'
}

pub fn (mut self MapperDummy) load_rom_bytes(data []u8) {
}

@[inline]
pub fn (mut self MapperDummy) read_byte(addr u16) u8 {
	return 0
}

@[inline]
pub fn (mut self MapperDummy) write_byte(addr u16, value u8) {
}

@[inline]
pub fn (mut self MapperDummy) read_word(addr u16) u16 {
	return 0
}

@[inline]
pub fn (mut self MapperDummy) write_word(addr u16, value u16) {
}

pub fn (mut self MapperDummy) get_pointer(addr u16) &u8 {
	return unsafe { nil }
}
