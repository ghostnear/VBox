module emulator_gameboy

@[heap]
struct PPU {
mut:
	vram [0x2000]u8
	oam  [0x100]u8
	lcdc [0xC]u8
}

pub fn (mut self PPU) update() {
	// TODO: not do this.
	self.lcdc[0x4] = 0x90
}

pub fn (mut self PPU) draw() {
}
