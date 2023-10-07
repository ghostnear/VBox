module emulator_gameboy

import os
import log
import sdl
import sdl_driver
import emulator_gameboy.mappers
import utils

[heap]
pub struct Emulator {
mut:
	// Externals
	window &sdl_driver.Window
	// Components
	ram &RAM
	cpu &CPU
	ppu &PPU
}

pub fn create_emulator(config Config) &Emulator {
	// Create components.
	ppu_component := PPU{}

	ram_component := RAM{
		cartridge: &mappers.MapperDummy{}
		bios: &mappers.MapperNone{}
		ppu: &ppu_component
	}

	cpu_component := CPU{
		ram: &ram_component
	}

	// Assemble components
	mut result := &Emulator{
		ram: &ram_component
		cpu: &cpu_component
		ppu: &ppu_component
		window: 0
	}

	// Pre-boot stuff.
	result.cpu.init()
	result.load_bios(config.bios_path)
	result.load_rom(config.rom_path)

	// Enable logging if needed.
	if config.debug_log_file != '' {
		result.cpu.debug = os.open_file(config.debug_log_file, 'w') or { panic(err) }
	}

	// Done.
	return result
}

fn (mut self Emulator) set_window(window &sdl_driver.Window) {
	self.window = window
}

pub fn (mut self Emulator) on_event(event &sdl.Event) {
}

fn (mut self Emulator) load_rom(path string) {
	// Open file.
	mut file := os.open(path) or { log.error("An error has occured. (${err})") exit(-1) }

	// Get ROM type and load.
	rom_type := file.read_bytes_at(1, 0x147)[0]
	match rom_type {
		0x00 {
			self.ram.cartridge = &mappers.MapperNone{}
		}
		0x01 {
			self.ram.cartridge = &mappers.MapperMBC1{}
		}
		else {
			log.error('Unimplemented mapper with id ${rom_type:02X}')
			exit(-1)
		}
	}
	self.ram.cartridge.load_rom_bytes(file.read_bytes(utils.get_file_size(mut file)))

	// TODO: print ROM data.
	// println('INFO: ROM Data:\n${self.ram.cartridge.rom_data.jsonify()}')

	log.info('Gameboy ROM loaded successfully.')
}

fn (mut self Emulator) load_bios(path string) {
	// No bios is also an option.
	if path == '' {
		self.cpu.set_post_boot_state()
		return
	}

	// Open file.
	mut file := os.open(path) or { panic("Couldn't open Gameboy bios file. (${err})") }

	// Make sure that we let the RAM know it has a BIOS.
	self.ram.bios.load_rom_bytes(file.read_bytes(utils.get_file_size(mut file)))
	self.ram.bios_flag = true

	println('INFO: Gameboy BIOS loaded successfully.')
}

pub fn (mut self Emulator) draw() {
	self.ppu.draw()
}

pub fn (mut self Emulator) update() {
	for _ in 0..10000 {
		self.cpu.step()
		self.ppu.update()
	}
}

pub fn (mut self Emulator) is_running() bool {
	return false
}
