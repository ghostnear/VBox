module vchip8

import os
import log

pub struct Emulator {
mut:
	debug_mode bool
	spawned_debug_thread bool
	debug_thread &thread bool = unsafe{ nil }

	memory     Memory
	display    Display
}

pub fn (mut self Emulator) configure(config map[string]string) !bool {
	file_contents := os.read_bytes(config['path']) or {
		return error('Could not load ROM at path: ${config['path']}')
	}

	expected_size := self.memory.ram.len - self.memory.pc
	if file_contents.len > expected_size {
		return error('ROM is too big to fit inside the memory of the VM! Expected: ${expected_size}B, got ${file_contents.len}B!')
	}

	// TODO: find out why this doesnt work with vmemcpy
	for index in 0 .. file_contents.len {
		self.memory.ram[index + self.memory.pc] = file_contents[index]
	}

	// Enable debug mode.
	if 'debug' in config {
		self.debug_mode = if config['debug'] == 'true' { true } else { false }
	}

	// Get display driver to use.
	if 'display' in config {
		match config['display'] {
			'stub' {
				self.display = DisplayStub{}
			}
			'sdl' {
				mut result := DisplaySDL{}
				self.display = result.configure(DisplaySDLConfig{
					width: 640
					height: 320
					title: 'VCHIP8'
				})
			}
			else {
				return error('Unknown display driver: ${config['display']}')
			}
		}
	}

	return true
}

fn (mut self Emulator) step() !bool {
	// Fetch
	opcode := self.memory.read2(self.memory.pc)
	self.memory.pc += 2

	// Stubs.
	x := u8((opcode & 0x0F00) >> 8)
	y := u8((opcode & 0x00F0) >> 4)
	nn := u8(opcode & 0x00FF)
	n := u8(opcode & 0x000F)

	match (opcode & 0xF000) >> 12 {
		0x0 {
			match opcode & 0x00FF {
				0xE0 {
					// CLS
					log.warn('CLS syscall not implemented!')
				}
				0xEE {
					// RET
					log.warn('RET not implemented!')
				}
				else {
					// SYS NNN
					// Ignore this, nobody implements them lol.
				}
			}
		}
		0x6 {
			// LD Vx, NN
			self.memory.v[x] = n
		}
		0xA {
			// LD I, NNN
			self.memory.i = opcode & 0x0FFF
		}
		else {
			return error('Unknown opcode: ${opcode:04X}')
		}
	}

	return true
}

pub fn (mut self Emulator) update(delta f64) bool {
	// If display called an end to this, we are gonna end.
	if self.display.update(delta) == false {
		return false
	}

	// Debug mode special stuff.
	if self.debug_mode {
		if !self.spawned_debug_thread {
			if self.debug_thread != unsafe { nil } {
				result := (*(self.debug_thread)).wait()
				if result == false {
					return false
				}
			}
			self.spawned_debug_thread = true
			self.debug_thread = &spawn self.execute_debug_command()
		}
		return true
	}

	// Normal step
	if !(self.step() or { false }) {
		return false
	}

	return true
}

pub fn (mut self Emulator) draw() {
}
