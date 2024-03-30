module vchip8

interface Display {
	get_pixel(x u16, y u16) u8
mut:
	width  u16
	height u16
	pixels []u8
	dirty  bool
	resize(newWidth u16, newHeight u16)
	clear()
	xor_pixel(x u16, y u16) bool
	update(dt f64) bool
	draw()
}

struct DisplayStub {
mut:
	width  u16
	height u16
	pixels []u8
	dirty  bool
}

fn (mut self DisplayStub) resize(newWidth u16, newHeight u16) {
	self.width = newWidth
	self.height = newHeight
	self.pixels = []u8{len: int(newWidth * newHeight / 8 + 1), cap: int(newWidth * newHeight / 8 + 1), init: 0x00}
	self.dirty = true
}

fn (mut self DisplayStub) clear() {
	for i in 0 .. self.pixels.len {
		self.pixels[i] = 0x00
	}
	self.dirty = true
}

@[inline]
fn (self DisplayStub) get_pixel(x u16, y u16) u8 {
	index := int(x + y * self.width)
	return (self.pixels[index / 8] >> (index % 8)) & 0b1
}

fn (mut self DisplayStub) xor_pixel(x u16, y u16) bool {
	index := int(x + y * self.width)
	result := self.get_pixel(x, y)
	self.pixels[index / 8] ^= 0b1 << (index % 8)
	return result != self.get_pixel(x, y)
}

@[inline]
fn (mut self DisplayStub) update(dt f64) bool {
	return true
}

fn (mut self DisplayStub) draw() {
}
