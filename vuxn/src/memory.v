module vuxn

struct Stack {
mut:
	end  u8   = 0x00
	data []u8 = []u8{len: 0x100, cap: 0x100, init: 0x00}
}

@[inline]
fn (mut self Stack) push(value u8) {
	self.data[self.end] = value
	self.end += 1
}

@[inline]
fn (mut self Stack) push2(value u16) {
	self.push(u8(value >> 8))
	self.push(u8(value))
}

@[inline]
fn (mut self Stack) pop() u8 {
	self.end -= 1
	return self.data[self.end]
}

@[inline]
fn (mut self Stack) pop2() u16 {
	return self.pop() | u16(self.pop()) << 8
}

@[inline]
fn (mut self Stack) vpush(condition bool, value u16) {
	if !condition {
		self.push(u8(value))
	} else {
		self.push2(value)
	}
}

@[inline]
fn (mut self Stack) vpop(condition bool) u16 {
	return if !condition {
		u16(self.pop())
	} else {
		u16(self.pop2())
	}
}

@[heap]
struct Memory {
mut:
	pc           u16  = 0x100
	ram          []u8 = []u8{len: 0x10000, cap: 0x10000, init: 0x00}
	work_stack   Stack
	return_stack Stack
}

@[inline]
fn (mut self Memory) read2(addr u16) u16 {
	return u16(self.ram[addr]) << 8 | self.ram[addr + 1]
}

@[inline]
fn (mut self Memory) vread(condition bool, address u16) u16 {
	return if !condition {
		u16(self.ram[u8(address)])
	} else {
		self.read2(address)
	}
}

@[inline]
fn (mut self Memory) write2(addr u16, value u16) {
	self.ram[addr] = u8(value >> 8)
	self.ram[addr + 1] = u8(value)
}

@[inline]
fn (mut self Memory) vwrite(condition bool, address u16, value u16) {
	if !condition {
		self.ram[u8(address)] = u8(value)
	} else {
		self.write2(address, value)
	}
}
