module sdl_driver

import sdl

[heap]
pub struct Window {
mut:
	closed     bool
	internal   &sdl.Window
	renderer   &sdl.Renderer
	now        u64
	last       u64
	delta_time f64
}

pub fn create_window(config WindowConfig) &Window {
	sdl.init(sdl.init_everything)

	mut result := &Window{
		internal: sdl.create_window(config.title.str, sdl.windowpos_centered, sdl.windowpos_centered,
			int(config.width), int(config.height), 0)
		renderer: 0
	}

	result.renderer = sdl.create_renderer(result.internal, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	result.now = sdl.get_performance_counter()
	result.last = sdl.get_performance_counter()

	return result
}

pub fn (mut self Window) get_renderer() &sdl.Renderer {
	return self.renderer
}

pub fn (mut self Window) get_delta() f64 {
	return self.delta_time
}

pub fn (mut self Window) should_close() bool {
	return self.closed
}

pub fn (mut self Window) update() {
	// Update delta time.
	self.last = self.now
	self.now = sdl.get_performance_counter()
	self.delta_time = f64((self.now - self.last)) / f64(sdl.get_performance_frequency())
}

pub fn (mut self Window) start_drawing() {
}

pub fn (mut self Window) end_drawing() {
	sdl.render_present(self.renderer)
}

pub fn (mut self Window) close() {
	self.closed = true

	sdl.quit()
}
