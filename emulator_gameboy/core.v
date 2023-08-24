module emulator_gameboy

import sdl_driver

[heap]
pub struct Emulator {
mut:
	window &sdl_driver.Window
}

pub fn create_emulator(config Config) &Emulator {
	result := &Emulator{
		window: 0
	}

	return result
}

pub fn (mut self Emulator) draw() {
}

pub fn (mut self Emulator) update() {
}
