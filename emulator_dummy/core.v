module emulator_dummy

import sdl_driver

[heap]
pub struct Emulator {
mut:
	window      &sdl_driver.Window
	shown_error bool
}

[inline]
pub fn create_emulator(config Config) &Emulator {
	result := &Emulator{
		window: 0
	}

	return result
}

pub fn (mut self Emulator) draw() {
}

pub fn (mut self Emulator) update() {
	if !self.shown_error {
		println('WARN: Dummy emulator does nothing...')
		self.shown_error = false
	}
}

pub fn (mut self Emulator) is_running() bool {
	return false
}
