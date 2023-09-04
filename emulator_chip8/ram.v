module emulator_chip8

struct RAM {
mut:
	data [0x10000]u8
}

[inline]
pub fn (mut self RAM) copy_bytes(source []u8, offset u16) {
	// TODO: surely there must be a nicer way to copy these
	for index in 0 .. source.len {
		self.data[offset + index] = source[index]
	}
}

[inline]
pub fn (mut self RAM) read_byte(addr u16) u8 {
	return self.data[addr]
}

[inline]
pub fn (mut self RAM) read_word(addr u16) u16 {
	return u16(self.read_byte(addr)) << 8 | self.read_byte(addr + 1)
}

[inline]
pub fn (mut self RAM) write_byte(addr u16, value u8) {
	self.data[addr] = value
}

[inline]
pub fn (mut self RAM) write_word(addr u16, value u16) {
	self.write_byte(addr + 1, u8(value & 0xFF))
	self.write_byte(addr, u8((value & 0xFF00) >> 8))
}
