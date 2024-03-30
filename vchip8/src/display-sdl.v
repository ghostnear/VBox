module vchip8

import sdl

struct DisplaySDLConfig {
	title  string
	width  u32
	height u32
}

struct DisplaySDL {
	DisplayStub
mut:
	window &sdl.Window = sdl.null
}

fn (mut self DisplaySDL) configure(config &DisplaySDLConfig) Display {
	self.window = sdl.create_window(config.title.str, sdl.windowpos_undefined, sdl.windowpos_undefined,
		config.width, config.height, u32(sdl.WindowFlags.opengl))
	return self
}

fn (mut self DisplaySDL) update(dt f64) bool {
	mut event := sdl.Event{}
	for sdl.poll_event(&event) != 0 {
		match event.@type {
			.quit {
				return false
			}
			else {}
		}
	}
	return true
}

fn (mut self DisplaySDL) draw() {
	if self.dirty == true {
		// TODO: rebuild the SDL texture.
		self.dirty = false
	}
}
