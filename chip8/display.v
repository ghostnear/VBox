module chip8

import sdl
import term
import utilities as utils

struct DisplayConfig {
mut:
	parent &VM = unsafe { nil }
}

[heap]
struct Display {
mut:
	vm          &VM = unsafe { nil }
	draw_flag   bool
	size        utils.Vec2[int]
	buffer      []u8
	sdl_display &sdl.Texture = sdl.null
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
		// Do nothing.
		.terminal {}
		// Lock the SDL_Texture and update it accordingly.
		.sdl {
			if self.sdl_display != sdl.null {
				sdl.set_render_target(self.vm.app.gfx.sdl_renderer, self.sdl_display)
				for y := 0; y < self.size.y; y++ {
					for x := 0; x < self.size.x; x++ {
						if self.get_pixel(x, y) == 1 {
							sdl.set_render_draw_color(self.vm.app.gfx.sdl_renderer, 0xAA,
								0xAA, 0xAA, 0xFF)
						} else {
							sdl.set_render_draw_color(self.vm.app.gfx.sdl_renderer, 0x11,
								0x11, 0x11, 0xFF)
						}
						sdl.render_draw_point(self.vm.app.gfx.sdl_renderer, x, y)
					}
				}
				sdl.set_render_target(self.vm.app.gfx.sdl_renderer, sdl.null)
			}
		}
		// This shouldn't happen.
		else {}
	}
}

pub fn (mut self Display) resize(newSize utils.Vec2[int]) {
	// Create buffer with new size
	self.size = newSize
	self.draw_flag = true
	self.buffer = []u8{len: self.size.x * self.size.y / 8, cap: self.size.x * self.size.y / 8, init: 0}

	// Recreate displays
	match self.vm.app.gfx.display_mode {
		// Clear terminal screen
		.terminal {
			term.clear()
		}
		// Create new SDL texture with the needed screen size.
		.sdl {
			if self.sdl_display != sdl.null {
				sdl.destroy_texture(self.sdl_display)
			}
			self.sdl_display = sdl.create_texture(self.vm.app.gfx.sdl_renderer, .rgb888,
				sdl.TextureAccess.target, newSize.x, newSize.y)
		}
		// Do nothing.
		else {}
	}
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
