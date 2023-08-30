module emulator_gameboy

import os
import sdl_driver
import emulator_gameboy.mappers
import utils

[heap]
pub struct Emulator {
mut:
	window &sdl_driver.Window

	ram &RAM
	cpu CPU
}

pub fn create_emulator(config Config) &Emulator {
	ram := RAM{
		cartridge: &mappers.MapperNone{}
		bios: &mappers.MapperNone{}
	}

	mut result := &Emulator{
		ram: &ram
		cpu: CPU{
			ram: &ram
		}
		window: 0
	}
	result.cpu.init()

	result.load_bios(config.bios_path)

	result.load_rom(config.rom_path)

	return result
}

fn (mut self Emulator) load_rom(path string) {
	mut file := os.open(path) or { panic("Couldn't open Gameboy ROM file. (${err})") }

	println('INFO: Gameboy ROM data:')
	title := file.read_bytes_at(16, 0x134).bytestr()
	version := file.read_bytes_at(1, 0x14C)[0]
	println("INFO: '${title}' ver '${version:02X}'")
	rom_type := file.read_bytes_at(1, 0x147)[0]
	match rom_type {
		0x00 {
			self.ram.cartridge = &mappers.MapperNone{}
		}
		else {
			panic('Unimplemented mapper with id ${rom_type:02X}')
		}
	}
	println("INFO: Mapper ('${self.ram.cartridge.name}')")

	self.ram.cartridge.set_rom_data(file.read_bytes(utils.get_file_size(mut file)))

	println('INFO: Gameboy ROM loaded successfully.')
}

fn (mut self Emulator) load_bios(path string) {
	mut file := os.open(path) or { panic("Couldn't open Gameboy bios file. (${err})") }

	self.ram.bios.set_rom_data(file.read_bytes(utils.get_file_size(mut file)))
	self.ram.bios_flag = true

	println('INFO: Gameboy BIOS loaded successfully.')
}

pub fn (mut self Emulator) draw() {
}

pub fn (mut self Emulator) update() {
	self.cpu.step()
}

pub fn (mut self Emulator) is_running() bool {
	return false
}
