module emulator_chip8

import sdl
import sdl_driver

struct PPU {
mut:
	window      &sdl_driver.Window
	data        []u8
	framebuffer &sdl.Texture = unsafe { 0 }
	draw_flag   bool
pub mut:
	width  int
	height int
}

pub fn (mut self PPU) draw() {
	if self.draw_flag == true {
		// Render to texture first.
		self.draw_flag = false

		sdl.set_render_target(self.window.get_renderer(), self.framebuffer)

		sdl.set_render_draw_color(self.window.get_renderer(), 0x11, 0x11, 0x11, 0xFF)

		sdl.render_clear(self.window.get_renderer())

		sdl.set_render_draw_color(self.window.get_renderer(), 0xEE, 0xEE, 0xEE, 0xFF)

		for index_y in 0 .. self.height {
			for index_x in 0 .. self.width {
				if self.get_pixel(index_x, index_y) {
					sdl.render_draw_point(self.window.get_renderer(), index_x, index_y)
				}
			}
		}

		sdl.set_render_target(self.window.get_renderer(), sdl.null)
	}
	sdl.render_copy(self.window.get_renderer(), self.framebuffer, sdl.null, sdl.null)
}

pub fn (mut self PPU) xor_pixel(pos_x int, pos_y int) bool {
	// Display clipping
	if pos_x >= self.width || pos_y >= self.height {
		return false
	}

	x := pos_x % self.width
	y := pos_y % self.height
	mut result := self.get_pixel(x, y)
	self.data[x / 8 + self.width / 8 * y] ^= 1 << (7 - x % 8)
	return result
}

fn (mut self PPU) get_pixel(x int, y int) bool {
	return ((self.data[x / 8 + self.width / 8 * y] >> (7 - x % 8)) & 1) != 0
}

[direct_array_access]
pub fn (mut self PPU) clear() {
	for index in 0 .. self.width * self.height / 8 {
		self.data[index] = 0
	}
	self.draw_flag = true
}

pub fn (mut self PPU) resize(width int, height int) {
	self.width = width
	self.height = height
	self.data = []u8{len: self.width * height / 8, init: 0}

	// Display stuff.
	if unsafe { self.window == 0 } {
		return
	}
	if self.framebuffer != 0 {
		sdl.destroy_texture(self.framebuffer)
	}
	self.framebuffer = sdl.create_texture(self.window.get_renderer(), sdl.Format.rgb888,
		sdl.TextureAccess.target, width, height)
	self.draw_flag = true
}
