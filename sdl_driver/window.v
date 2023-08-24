module sdl_driver

import sdl

[heap]
pub struct Window {
mut:
	closed   bool
	internal &sdl.Window
	renderer &sdl.Renderer
	event    sdl.Event
}

pub fn create_window(config WindowConfig) &Window {
	sdl.init(sdl.init_everything)

	mut result := &Window{
		internal: sdl.create_window(config.title.str, sdl.windowpos_centered, sdl.windowpos_centered,
			int(config.width), int(config.height), 0)
		renderer: 0
	}

	result.renderer = sdl.create_renderer(result.internal, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))

	return result
}

pub fn (self &Window) should_close() bool {
	return self.closed
}

pub fn (mut self Window) update() {
	self.poll_events()
}

pub fn (mut self Window) start_drawing() {
}

pub fn (mut self Window) end_drawing() {
}

pub fn (mut self Window) close() {
	self.closed = true

	sdl.quit()
}

fn (mut self Window) poll_events() {
	for 0 < sdl.poll_event(&self.event) {
		match self.event.@type {
			.quit {
				self.close()
			}
			else {}
		}
	}
}
