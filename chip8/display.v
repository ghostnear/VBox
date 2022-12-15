module chip8

import term
import utilities as utils

struct DisplayConfig {
mut:
	parent &VM = unsafe { nil }
}

[heap]
struct Display {
mut:
	vm        &VM = unsafe { nil }
	draw_flag bool
	size      utils.Vec2[int]
	buffer    []u8
}

[inline]
pub fn (mut self Display) get_pixel(x int, y int) u8 {
	return (self.buffer[x / 8 + self.size.x * y / 8] >> (x % 8)) & 1
}

[inline]
pub fn (mut self Display) set_pixel(x int, y int) {
	self.buffer[x / 8 + self.size.x * y / 8] |= 1 << (x % 8)
}

[inline]
pub fn (mut self Display) xor_pixel(pos_x int, pos_y int) int {
	x := pos_x % self.size.x
	y := pos_y % self.size.y
	mut result := self.get_pixel(x, y)
	self.buffer[x / 8 + self.size.x * y / 8] ^= 1 << (x % 8)
	return result
}

// Render the dispaly to the specified target.
// For SDL it is an SDL_Texture, for terminal it is the IO.
pub fn (mut self Display) render() {
	match self.vm.app.gfx.display_mode {
		// Print directly to the screen.
		.terminal {
			term.hide_cursor()
			term.set_cursor_position(x: 0, y: 0)
			for y := 0; y < self.size.y; y++ {
				mut line := ''
				for x := 0; x < self.size.x; x++ {
					if self.get_pixel(x, y) == 1 {
						line += '█'
					} else {
						line += ' '
					}
				}
				println(line)
			}
		}
		// Lock the SDL_Texture and update it accordingly.
		// TODO
		.sdl {}
		// This shouldn't happen.
		else {}
	}
}

pub fn (mut self Display) resize(newSize utils.Vec2[int]) {
	// Create buffer with new size
	self.size = newSize
	self.draw_flag = true
	self.buffer = []u8{len: self.size.x * self.size.y / 8, cap: self.size.x * self.size.y / 8, init: 0}

	// TODO: do stuff to the display depending on the output (resize texture for SDL or clear screen for terminal)
}

pub fn (mut self Display) clear() {
	self.draw_flag = true
	for index := 0; index < self.buffer.len; index++ {
		self.buffer[index] = 0
	}
}

[inline]
pub fn new_dsp(cfg DisplayConfig, parent &VM) &Display {
	mut display := &Display{
		vm: parent
		draw_flag: true
	}
	display.resize(utils.Vec2[int]{
		x: 64
		y: 32
	})
	return display
}
