module vchip8

@[heap]
struct Memory {
mut:
	pc  u16  = 0x200
	ram []u8 = []u8{len: 0x10000, cap: 0x10000, init: 0x00}
	v   []u8 = []u8{len: 0x10, cap: 0x10, init: 0x00}
	i   u16  = 0x00
}

@[inline]
fn (mut self Memory) read(addr u16) u8 {
	return self.ram[addr]
}

@[inline]
fn (mut self Memory) read2(addr u16) u16 {
	return u16(self.ram[addr]) << 8 | self.ram[addr + 1]
}

@[inline]
fn (mut self Memory) write(addr u16, value u8) {
	self.ram[addr] = value
}

@[inline]
fn (mut self Memory) write2(addr u16, value u16) {
	self.ram[addr] = u8(value >> 8)
	self.ram[addr + 1] = u8(value)
}
