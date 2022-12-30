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

/*
*	Pixel operations.
*/

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

// Render the display to the specified target.
// For SDL it is an SDL_Texture, for terminal it is a string.
pub fn (mut self Display) render() {
	match self.vm.app.gfx.display_mode {
		.terminal {
			// TODO: RENDER ALL TO A STRING.
		}
		.sdl {
			// Draw to the display texture.
			sdl.set_render_target(self.vm.app.gfx.sdl_renderer, self.sdl_display)
			for y := 0; y < self.size.y; y++ {
				for x := 0; x < self.size.x; x++ {
					// TODO: replace this with texture updates instead of point drawings.

					// If pixel is set, use the foreground color.
					if self.get_pixel(x, y) == 1 {
						sdl.set_render_draw_color(self.vm.app.gfx.sdl_renderer, 0xAA,
							0xAA, 0xAA, 0xFF)
					}
					// Use the background color.
					else {
						sdl.set_render_draw_color(self.vm.app.gfx.sdl_renderer, 0x11,
							0x11, 0x11, 0xFF)
					}
					sdl.render_draw_point(self.vm.app.gfx.sdl_renderer, x, y)
				}
			}

			// Reset the render target.
			sdl.set_render_target(self.vm.app.gfx.sdl_renderer, sdl.null)
		}
		// This shouldn't happen.
		else {}
	}
}

// Resize the display to a new size.
pub fn (mut self Display) resize(newSize utils.Vec2[int]) {
	self.size = newSize
	self.draw_flag = true
	self.buffer = []u8{len: self.size.x * self.size.y / 8, cap: self.size.x * self.size.y / 8, init: 0}

	// Recreate displays
	match self.vm.app.gfx.display_mode {
		.terminal {
			// Clear terminal screen.
			term.clear()
		}
		.sdl {
			// Destroy the texture if it already exists.
			if self.sdl_display != sdl.null {
				sdl.destroy_texture(self.sdl_display)
			}

			// Create new texture with the needed screen size.
			self.sdl_display = sdl.create_texture(self.vm.app.gfx.sdl_renderer, .rgb888,
				sdl.TextureAccess.target, newSize.x, newSize.y)
		}
		// Do nothing.
		else {}
	}
}

// Clear the VM screen.
pub fn (mut self Display) clear() {
	self.draw_flag = true
	for index := 0; index < self.buffer.len; index++ {
		self.buffer[index] = 0
	}
}

// Create a new CHIP8 display manager.
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
