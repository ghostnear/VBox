module vuxn

import os
import log

pub struct Emulator {
mut:
	memory  Memory
	devices Devices
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

	// Add all the configured devices.
	for device in config['devices'].split(',') {
		if device == '' {
			break
		}
		match device {
			'console' {
				self.devices.map_device(Console{
					parent: self
				}, 1)
			}
			else {
				log.error('Unknown device: ${device}')
				return false
			}
		}
	}

	return true
}

fn (mut self Emulator) trigger_vector(address u16) {
	self.memory.return_stack.push2(self.memory.pc)
	self.memory.pc = address
}

fn (mut self Emulator) step() bool {
	opcode := self.memory.ram[self.memory.pc]
	self.memory.pc += 1

	// Instruction working size.
	mut wsize := (opcode & 0x20) != 0

	// Get stack depending on the stack bit of the opcode.
	mut stack := if opcode & 0x40 != 0 { &self.memory.return_stack } else { &self.memory.work_stack }
	mut other_stack := if opcode & 0x40 == 0 {
		&self.memory.return_stack
	} else {
		&self.memory.work_stack
	}

	// Keep mode (do not consume items, i.e do not modify the OG stack on pop)
	mut keep := (opcode & 0x80) != 0	// The bane of my clean code experience
	old_end := stack.end

	match opcode & 0x1F {
		// Special opcodes.
		0x00 {
			match opcode {
				// Break
				0x00 {
					if self.memory.return_stack.end == 0 {
						return false
					}
					self.memory.pc = self.memory.return_stack.pop2()
				}
				// Jump conditional instant.
				0x20 {
					if stack.pop() == 0 {
						self.memory.pc += 2
					} else {
						self.memory.pc += self.memory.read2(self.memory.pc) + 2
					}
				}
				// Jump instant.
				0x40 {
					self.memory.pc += self.memory.read2(self.memory.pc) + 2
				}
				// Jump stash return instant.
				0x60 {
					stack.push2(self.memory.pc + 2)
					self.memory.pc += self.memory.read2(self.memory.pc) + 2
				}
				// Push more.
				0xA0, 0xE0 {
					stack.push(self.memory.ram[self.memory.pc])
					self.memory.pc += 1
					stack.push(self.memory.ram[self.memory.pc])
					self.memory.pc += 1
				}
				// Push 1.
				0x80, 0xC0 {
					stack.push(self.memory.ram[self.memory.pc])
					self.memory.pc += 1
				}
				else {
					log.error('Invalid special opcode found at address 0x${self.memory.pc - 1:04X}: 0x${opcode:02X}')
					return false
				}
			}
		}
		// INC
		0x01 {
			value := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, value + 1)
		}
		// POP
		0x02 {
			stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
		}
		// NIP
		0x03 {
			a := stack.vpop(wsize)
			stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a)
		}
		// SWP
		0x04 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a)
			stack.vpush(wsize, b)
		}
		// ROT
		0x05 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			c := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, b)
			stack.vpush(wsize, a)
			stack.vpush(wsize, c)
		}
		// DUP
		0x06 {
			value := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, value)
			stack.vpush(wsize, value)
		}
		// OVR
		0x07 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, b)
			stack.vpush(wsize, a)
			stack.vpush(wsize, b)
		}
		// EQU
		0x08 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.push(u8(a == b))
		}
		// NEQ
		0x09 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.push(u8(a != b))
		}
		// GTH
		0x0A {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.push(u8(a < b))
		}
		// LTH
		0x0B {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.push(u8(a > b))
		}
		// JMP
		0x0C {
			if !wsize {
				signed_byte := i8(stack.pop())
				if signed_byte < 0 {
					self.memory.pc -= u8(-signed_byte)
				} else {
					self.memory.pc += u8(signed_byte)
				}
			} else {
				self.memory.pc = stack.pop2()
			}
			if keep {
				stack.end = old_end
			}
		}
		// JCN
		0x0D {
			address := stack.vpop(wsize)
			condition := stack.pop()
			if condition != 0 {
				if !wsize {
					signed_byte := i8(address)
					if signed_byte < 0 {
						self.memory.pc -= u8(-signed_byte)
					} else {
						self.memory.pc += u8(signed_byte)
					}
				} else {
					self.memory.pc = address
				}
			}
			if keep {
				stack.end = old_end
			}
		}
		// JSR
		0x0E {
			self.memory.return_stack.push2(self.memory.pc)
			if !wsize {
				signed_byte := i8(stack.pop())
				if signed_byte < 0 {
					self.memory.pc -= u8(-signed_byte)
				} else {
					self.memory.pc += u8(signed_byte)
				}
			} else {
				self.memory.pc = stack.pop2()
			}
		}
		// STH
		0x0F {
			value := stack.vpop(wsize)
			other_stack.vpush(wsize, value)
			if keep {
				stack.end = old_end
			}
		}
		// LDZ
		0x10 {
			address := stack.pop()
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, self.memory.vread(wsize, address))
		}
		// STZ
		0x11 {
			address := stack.pop()
			value := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			self.memory.vwrite(wsize, address, value)
		}
		// LDR
		0x12 {
			offset := i8(stack.pop())
			new_address := if offset < 0 {
				self.memory.pc - u8(-offset)
			} else {
				self.memory.pc + u8(offset)
			}
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, self.memory.vread(wsize, new_address))
		}
		// STR
		0x13 {
			offset := i8(stack.pop())
			new_address := if offset < 0 {
				self.memory.pc - u8(-offset)
			} else {
				self.memory.pc + u8(offset)
			}
			value := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			self.memory.vwrite(wsize, new_address, value)
		}
		// LDA
		0x14 {
			address := stack.pop2()
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, self.memory.vread(wsize, address))
		}
		// STA
		0x15 {
			address := stack.pop2()
			value := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			self.memory.vwrite(wsize, address, value)
		}
		// DEI
		0x16 {
			stack.vpush(wsize, self.devices.vread(wsize, stack.pop()))
			if keep {
				stack.end = old_end
			}
		}
		// DEO
		0x17 {
			self.devices.vwrite(wsize, stack.pop(), stack.vpop(wsize))
		}
		// ADD
		0x18 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a + b)
		}
		// SUB
		0x19 {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, b - a)
		}
		// MUL 
		0x1A {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a * b)
		}
		// DIV
		0x1B {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, if a != 0 { b / a } else { 0 })
		}
		// AND
		0x1C {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a & b)
		}
		// ORA
		0x1D {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a | b)
		}
		// EOR
		0x1E {
			a := stack.vpop(wsize)
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			stack.vpush(wsize, a ^ b)
		}
		// SFT
		0x1F {
			a := stack.pop()
			b := stack.vpop(wsize)
			if keep {
				stack.end = old_end
			}
			r := (b >> (a & 0xF)) << ((a & 0xF0) >> 4)
			stack.vpush(wsize, r)
		}
		else {
			log.error('Invalid opcode found at address 0x${self.memory.pc - 1:04X}: 0x${opcode:02X}')
			return false
		}
	}

	return true
}

pub fn (mut self Emulator) update(delta f32) bool {
	if !self.step() {
		return false
	}

	return true
}

pub fn (mut self Emulator) draw() {
}
