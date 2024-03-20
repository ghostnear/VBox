module emulator_chip8

import log
import rand

fn unknown_opcode(mut self CPU, opcode u16) {
	println('ERROR: Unknown instruction ${opcode:04X} detected at PC ${self.pc - 2:04X}!')
	self.halt_flag = true
	self.key_register = 0xFF
}

@[inline]
pub fn (mut self CPU) populate_instruction_tables() {
	// System calls
	self.instruction_table[0x0] = fn (mut self CPU, opcode u16) {
		match opcode & 0xFF {
			// CLS
			0xE0 {
				self.ppu.clear()
			}
			// RET
			0xEE {
				self.sp--
				self.pc = self.stack[self.sp]
			}
			else {
				unknown_opcode(mut self, opcode)
			}
		}
	}

	// 1NNN - JP NNN
	self.instruction_table[0x1] = fn (mut self CPU, opcode u16) {
		if self.pc - 2 == opcode & 0xFFF {
			log.warn('Infinite jump detected! Stopping emulation.')
			self.halt_flag = true
		}
		self.pc = opcode & 0xFFF
	}

	// 2NNN - CALL NNN
	self.instruction_table[0x2] = fn (mut self CPU, opcode u16) {
		self.stack[self.sp] = self.pc
		self.sp++
		self.pc = opcode & 0xFFF
	}

	// 3XNN - SKPE VX, NN
	self.instruction_table[0x3] = fn (mut self CPU, opcode u16) {
		if self.v[opcode & 0xF00 >> 8] == u8(opcode & 0xFF) {
			self.pc += 2
		}
	}

	// 4XNN - SKPNE VX, NN
	self.instruction_table[0x4] = fn (mut self CPU, opcode u16) {
		if self.v[opcode & 0xF00 >> 8] != u8(opcode & 0xFF) {
			self.pc += 2
		}
	}

	// 5XY0 - SKPE VX, VY
	self.instruction_table[0x5] = fn (mut self CPU, opcode u16) {
		if opcode & 0xF != 0 {
			return
		}

		if self.v[opcode & 0xF00 >> 8] == self.v[opcode & 0xF0 >> 4] {
			self.pc += 2
		}
	}

	// 6XNN - LD VX, NN
	self.instruction_table[0x6] = fn (mut self CPU, opcode u16) {
		self.v[opcode & 0xF00 >> 8] = u8(opcode & 0xFF)
	}

	// 7XNN - ADD VX, NN
	self.instruction_table[0x7] = fn (mut self CPU, opcode u16) {
		self.v[opcode & 0xF00 >> 8] += u8(opcode & 0xFF)
	}

	// 8XYN - Arithmetic opcodes
	self.instruction_table[0x8] = fn (mut self CPU, opcode u16) {
		match opcode & 0xF {
			// LD VX, VY
			0x0 {
				self.v[opcode & 0xF00 >> 8] = self.v[opcode & 0xF0 >> 4]
			}
			// OR VX, VY
			0x1 {
				self.v[opcode & 0xF00 >> 8] |= self.v[opcode & 0xF0 >> 4]
				self.v[0xF] = 0x00
			}
			// AND VX, VY
			0x2 {
				self.v[opcode & 0xF00 >> 8] &= self.v[opcode & 0xF0 >> 4]
				self.v[0xF] = 0x00
			}
			// XOR VX, VY
			0x3 {
				self.v[opcode & 0xF00 >> 8] ^= self.v[opcode & 0xF0 >> 4]
				self.v[0xF] = 0x00
			}
			// ADD VX, VY
			0x4 {
				mut flag := u8(0x00)
				if 0xFF - self.v[opcode & 0xF0 >> 4] < self.v[opcode & 0xF00 >> 8] {
					flag = 0x01
				}
				self.v[opcode & 0xF00 >> 8] += self.v[opcode & 0xF0 >> 4]
				self.v[0xF] = flag
			}
			// SUB VX, VY
			0x5 {
				mut flag := u8(0x00)
				if self.v[opcode & 0xF0 >> 4] < self.v[opcode & 0xF00 >> 8] {
					flag = 0x01
				}
				self.v[opcode & 0xF00 >> 8] -= self.v[opcode & 0xF0 >> 4]
				self.v[0xF] = flag
			}
			// SHR VX (TODO: quirks)
			0x6 {
				mut flag := u8(self.v[opcode & 0xF0 >> 4] & 0b1)
				self.v[opcode & 0xF00 >> 8] = self.v[opcode & 0xF0 >> 4] >> 1
				self.v[0xF] = flag
			}
			// LD VX, VY - VX
			0x7 {
				mut flag := u8(0x00)
				if self.v[opcode & 0xF0 >> 4] > self.v[opcode & 0xF00 >> 8] {
					flag = 0x01
				}
				self.v[opcode & 0xF00 >> 8] = self.v[opcode & 0xF0 >> 4] - self.v[opcode & 0xF00 >> 8]
				self.v[0xF] = flag
			}
			// SHL VX (TODO: quirks)
			0xE {
				mut flag := u8(self.v[opcode & 0xF0 >> 4] & (1 << 7)) >> 7
				self.v[opcode & 0xF00 >> 8] = self.v[opcode & 0xF0 >> 4] << 1
				self.v[0xF] = flag
			}
			else {
				unknown_opcode(mut self, opcode)
			}
		}
	}

	// 9XY0 - SKPNE VX, VY
	self.instruction_table[0x9] = fn (mut self CPU, opcode u16) {
		if opcode & 0xF != 0 {
			unknown_opcode(mut self, opcode)
		}

		if self.v[opcode & 0xF00 >> 8] != self.v[opcode & 0xF0 >> 4] {
			self.pc += 2
		}
	}

	// ANNN - LD I, NNN
	self.instruction_table[0xA] = fn (mut self CPU, opcode u16) {
		self.i = opcode & 0xFFF
	}

	// BXNN - JMP V0 + NNN
	self.instruction_table[0xB] = fn (mut self CPU, opcode u16) {
		self.pc = u16(self.v[0]) + opcode & 0xFFF
	}

	// CXNN - LD VX, RND NN
	self.instruction_table[0xC] = fn (mut self CPU, opcode u16) {
		self.v[(opcode & 0xF00) >> 8] = rand.u8() & u8(opcode & 0xFF)
	}

	// DXYN - DRW VX, VY, N
	self.instruction_table[0xD] = fn (mut self CPU, opcode u16) {
		self.v[0xF] = 0x00

		x_pos := self.v[(opcode & 0xF00) >> 8] % self.ppu.width
		y_pos := self.v[(opcode & 0xF0) >> 4] % self.ppu.height

		// Go trough the sprite.
		for index in 0 .. opcode & 0xF {
			bytevalue := self.ram.read_byte(self.i + index)
			for bit in 0 .. 8 {
				if (bytevalue >> (7 - bit)) & 1 != 0 {
					self.ppu.draw_flag = true
					if self.ppu.xor_pixel(x_pos + bit, y_pos + index) == true {
						self.v[0xF] = 1
					}
				}
			}
		}
	}

	// EXNN - Keyboard opcodes
	self.instruction_table[0xE] = fn (mut self CPU, opcode u16) {
		match opcode & 0xFF {
			// SKPP VX
			0x9E {
				if self.input.get_key(self.v[(opcode & 0xF00) >> 8]) != 0 {
					self.pc += 2
				}
			}
			// SKPNP VX
			0xA1 {
				if self.input.get_key(self.v[(opcode & 0xF00) >> 8]) == 0 {
					self.pc += 2
				}
			}
			else {
				unknown_opcode(mut self, opcode)
			}
		}
	}

	// FXNN - Special opcodes
	self.instruction_table[0xF] = fn (mut self CPU, opcode u16) {
		match opcode & 0xFF {
			// LD VX, DT
			0x07 {
				self.v[(opcode & 0xF00) >> 8] = self.delta_timer.get_value()
			}
			// GETKEY VX
			0x0A {
				self.halt_flag = true
				self.key_register = u8((opcode & 0xF00) >> 8)
			}
			// LD DT, VX
			0x15 {
				self.delta_timer.set_value(self.v[(opcode & 0xF00) >> 8])
			}
			// LD ST, VX
			0x18 {
				self.sound_timer.set_value(self.v[(opcode & 0xF00) >> 8])
			}
			// ADD I, VX
			0x1E {
				self.i += self.v[(opcode & 0xF00) >> 8]
			}
			// LD I, hex(VX)
			0x29 {
				self.i = u16(self.v[(opcode & 0xF00) >> 8]) * 5
			}
			// BCD VX, [I]
			0x33 {
				self.ram.write_byte(self.i, self.v[(opcode & 0xF00) >> 8] / 100)
				self.ram.write_byte(self.i + 1, (self.v[(opcode & 0xF00) >> 8] / 10) % 10)
				self.ram.write_byte(self.i + 2, self.v[(opcode & 0xF00) >> 8] % 10)
			}
			// STR [I], VX
			0x55 {
				for index in 0 .. (opcode & 0xF00) >> 8 + 1 {
					self.ram.write_byte(self.i + index, self.v[index])
				}
				self.i += (opcode & 0xF00) >> 8 + 1
			}
			// STR VX, [I]
			0x65 {
				for index in 0 .. (opcode & 0xF00) >> 8 + 1 {
					self.v[index] = self.ram.read_byte(self.i + index)
				}
				self.i += (opcode & 0xF00) >> 8 + 1
			}
			else {
				unknown_opcode(mut self, opcode)
			}
		}
	}
}
