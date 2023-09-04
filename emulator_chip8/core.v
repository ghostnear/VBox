module emulator_chip8

import os
import utils
import sdl
import sdl_driver

[heap]
pub struct Emulator {
mut:
	window &sdl_driver.Window
	// Components
	ram         RAM
	cpu         &CPU
	ppu         &PPU
	input       Input
	delta_timer Timer
	sound_timer Timer
}

pub fn create_emulator(config Config) &Emulator {
	// Create components
	mut ppu := &PPU{
		window: 0
	}
	ppu.resize(64, 32)

	mut cpu := &CPU{
		ppu: ppu
		instruction_rate: config.instruction_rate
	}
	cpu.populate_instruction_tables()

	// Add to the emulator.
	mut result := &Emulator{
		window: 0
		cpu: cpu
		ppu: ppu
	}
	result.cpu.ram = &result.ram
	result.cpu.input = &result.input
	result.cpu.delta_timer = &result.delta_timer
	result.cpu.sound_timer = &result.sound_timer

	result.load_rom(config.rom_path, 0x200)

	return result
}

fn (mut self Emulator) set_window(window &sdl_driver.Window) {
	self.window = window
	self.ppu.window = window
	self.ppu.resize(self.ppu.width, self.ppu.height)
}

[inline]
fn (mut self Emulator) load_rom(path string, offset u16) {
	// Open file.
	mut file := os.open(path) or { panic("Couldn't open CHIP8 ROM file. (${err})") }

	self.ram.copy_bytes(file.read_bytes(utils.get_file_size(mut file)), offset)
	self.cpu.pc = offset

	self.ram.copy_bytes(font_lowres, 0)
}

pub fn (mut self Emulator) on_event(event &sdl.Event) {
	match event.@type {
		.keydown {
			self.input.set_key(event.key.keysym.sym, 1)
		}
		.keyup {
			self.input.set_key(event.key.keysym.sym, 0)
		}
		else {}
	}
}

pub fn (mut self Emulator) draw() {
	self.ppu.draw()
}

pub fn (mut self Emulator) update() {
	self.delta_timer.update(self.window.get_delta())
	self.sound_timer.update(self.window.get_delta())
	self.cpu.update(self.window.get_delta())
}

pub fn (mut self Emulator) is_running() bool {
	return false
}
