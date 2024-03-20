module emulator_gameboy

@[inline]
pub fn (mut self PPU) write_vram_byte(addr u16, val u8) {
	self.vram[addr] = val
}

@[inline]
pub fn (mut self PPU) read_vram_byte(addr u16) u8 {
	return self.vram[addr]
}

@[inline]
pub fn (mut self PPU) get_vram_pointer(addr u16) &u8 {
	return &self.vram[addr]
}

@[inline]
pub fn (mut self PPU) write_lcdc_byte(addr u16, val u8) {
	self.lcdc[addr] = val
}

@[inline]
pub fn (mut self PPU) read_lcdc_byte(addr u16) u8 {
	return self.lcdc[addr]
}

@[inline]
pub fn (mut self PPU) get_lcdc_pointer(addr u16) &u8 {
	return &self.lcdc[addr]
}

@[inline]
pub fn (mut self PPU) write_oam_byte(addr u16, val u8) {
	self.oam[addr] = val
}

@[inline]
pub fn (mut self PPU) read_oam_byte(addr u16) u8 {
	return self.oam[addr]
}

@[inline]
pub fn (mut self PPU) get_oam_pointer(addr u16) &u8 {
	return &self.oam[addr]
}
