module emulator_chip8

import time

struct CPU {
mut:
	// Other components
	ram         &RAM   = unsafe { 0 }
	ppu         &PPU   = unsafe { 0 }
	input       &Input = unsafe { 0 }
	delta_timer &Timer = unsafe { 0 }
	sound_timer &Timer = unsafe { 0 }
	// Instruction tables for nicer CPU organizing.
	instruction_table [0x10]fn (mut CPU, u16)
	// Registers
	pc    u16
	i     u16
	v     [0x10]u8
	sp    u8
	stack [0x10]u16
	// Flags
	halt_flag       bool
	key_register    u8 = 0xFF
	key_to_wait_for u8 = 0xFF
	// Internal timers
	timer            f64
	instruction_rate f64 = 500.0
}

pub fn (mut self CPU) update(delta f64) {
	if !self.halt_flag {
		self.timer += delta
		for self.timer > 1.0 / self.instruction_rate && !self.halt_flag {
			self.step()
			self.timer -= 1.0 / self.instruction_rate
		}
		time.sleep(1000000000.0 / self.instruction_rate - self.timer)
	} else {
		self.timer = 0
		if self.key_register != 0xFF {
			if self.key_to_wait_for == 0xFF {
				self.key_to_wait_for = self.input.get_first_key_pressed()
				return
			}

			if self.input.get_key(self.key_to_wait_for) == 0 {
				self.v[self.key_register] = self.key_to_wait_for
				self.halt_flag = false
				self.key_register = 0xFF
				self.key_to_wait_for = 0xFF
			}
		}
		return
	}
}

fn (mut self CPU) step() {
	opcode := self.ram.read_word(self.pc)
	self.pc += 2

	self.instruction_table[(opcode & 0xF000) >> 12](mut self, opcode)
}
