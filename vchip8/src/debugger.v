module vchip8

import os
import term
import strconv

fn (mut self Emulator) print_registers() {
	println('${term.blue("I:")} 0x${self.memory.i:04X}')
	println('${term.blue("PC:")} 0x${self.memory.pc:04X}')
	// println("SP: 0x${self.memory.sp:02X}")
	// println("DT: 0x${self.memory.dt:02X}")
	// println("ST: 0x${self.memory.st:02X}")
	for index in 0 .. 0x10 {
		print('${term.blue("V${index:01X}:")} 0x${self.memory.v[index]:02X} ')
		if index % 4 == 3 && index != 0x10 {
			print('\n')
		}
	}
}

fn (mut self Emulator) disassemble_instruction(instruction u16) string {
	match (instruction & 0xF000) >> 12 {
		0x0 {
			match instruction & 0x00FF {
				0xE0 { return 'CLS' }
				0xEE { return 'RET' }
				else { return 'SYS 0x${instruction & 0x0FFF:03X}' }
			}
		}
		0x1 {
			return 'JP 0x${instruction & 0x0FFF:03X}'
		}
		0x2 {
			return 'CALL 0x${instruction & 0x0FFF:03X}'
		}
		0x3 {
			return 'SE V${(instruction & 0x0F00) >> 8:01X}, 0x${instruction & 0x00FF:02X}'
		}
		0x4 {
			return 'SNE V${(instruction & 0x0F00) >> 8:01X}, 0x${instruction & 0x00FF:02X}'
		}
		0x5 {
			return 'SE V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}'
		}
		0x6 {
			return 'LD V${(instruction & 0x0F00) >> 8:01X}, 0x${instruction & 0x00FF:02X}'
		}
		0x7 {
			return 'ADD V${(instruction & 0x0F00) >> 8:01X}, 0x${instruction & 0x00FF:02X}'
		}
		0x8 {
			match instruction & 0x000F {
				0x0 { return 'LD V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0x1 { return 'OR V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0x2 { return 'AND V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0x3 { return 'XOR V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0x4 { return 'ADD V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0x5 { return 'SUB V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0x6 { return 'SHR V${(instruction & 0x0F00) >> 8:01X}' }
				0x7 { return 'SUBN V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}' }
				0xE { return 'SHL V${(instruction & 0x0F00) >> 8:01X}' }
				else { return 'UNKNOWN' }
			}
		}
		0x9 {
			return 'SNE V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}'
		}
		0xA {
			return 'LD I, 0x${instruction & 0x0FFF:03X}'
		}
		0xB {
			return 'JP V0, 0x${instruction & 0x0FFF:03X}'
		}
		0xC {
			return 'RND V${(instruction & 0x0F00) >> 8:01X}, 0x${instruction & 0x00FF:02X}'
		}
		0xD {
			return 'DRW V${(instruction & 0x0F00) >> 8:01X}, V${(instruction & 0x00F0) >> 4:01X}, 0x${instruction & 0x000F:01X}'
		}
		0xE {
			match instruction & 0x00FF {
				0x9E { return 'SKP V${(instruction & 0x0F00) >> 8:01X}' }
				0xA1 { return 'SKNP V${(instruction & 0x0F00) >> 8:01X}' }
				else { return 'UNKNOWN' }
			}
		}
		0xF {
			match instruction & 0x00FF {
				0x07 { return 'LD V${(instruction & 0x0F00) >> 8:01X}, DT' }
				0x0A { return 'LD V${(instruction & 0x0F00) >> 8:01X}, K' }
				0x15 { return 'LD DT, V${(instruction & 0x0F00) >> 8:01X}' }
				0x18 { return 'LD ST, V${(instruction & 0x0F00) >> 8:01X}' }
				0x1E { return 'ADD I, V${(instruction & 0x0F00) >> 8:01X}' }
				0x29 { return 'LD F, V${(instruction & 0x0F00) >> 8:01X}' }
				0x33 { return 'LD B, V${(instruction & 0x0F00) >> 8:01X}' }
				0x55 { return 'LD [I], V${(instruction & 0x0F00) >> 8:01X}' }
				0x65 { return 'LD V${(instruction & 0x0F00) >> 8:01X}, [I]' }
				else { return 'UNKNOWN' }
			}
		}
		else {
			return 'UNKNOWN'
		}
	}
	return 'UNKNOWN'
}

fn (mut self Emulator) execute_debug_command() bool {
	print(term.yellow('(vchip8dbg)> '))
	command := os.get_raw_line().trim_space()

	// Easy one line commands.
	if command.compare('exit') == 0 || command.compare('q') == 0 || command.compare('quit') == 0 {
		return false
	}

	if command.compare('step') == 0 || command.compare('s') == 0 {
		self.step() or {
			println(term.red('Failed to execute the instruction:\n\t${err}.'))
			self.memory.pc -= 2
		}
		return true
	}

	// Start splitting the commands as the one liners ended.
	commands := command.split(' ')
	if commands.len == 0 {
		return true
	}

	// Printings.
	if commands[0].compare('print') == 0 || commands[0].compare('p') == 0 {
		if commands.len < 2 {
			println(term.red('Invalid number of arguments for print command.'))
			return true
		}

		if commands[1].compare('registers') == 0 || commands[1].compare('r') == 0 {
			self.print_registers()
			return true
		}

		if commands[1].compare('memory-byte') == 0 || commands[1].compare('mb') == 0 {
			if commands.len < 3 {
				println(term.red('Invalid number of arguments for print address command.'))
				return true
			}

			// Parsing the address.
			address := u16(strconv.common_parse_int(commands[2], 16, 16, false, false) or {
				println(term.red('Invalid address.'))
				return true
			})

			// Printing the address value.
			println('0x${address:04X}: 0x${self.memory.read(address):02X}')
			return true
		}

		if commands[1].compare('memory-word') == 0 || commands[1].compare('mw') == 0 {
			if commands.len < 3 {
				println(term.red('Invalid number of arguments for print address command.'))
				return true
			}

			// Parsing the address.
			address := u16(strconv.common_parse_int(commands[2], 16, 16, false, false) or {
				println(term.red('Invalid address.'))
				return true
			})

			// Printing the address value.
			println('0x${address:04X}: 0x${self.memory.read2(address):04X}')
			return true
		}

		println(term.red('Invalid print command.'))
		return true
	}

	// Dissassemble instructions around PC.
	if commands[0].compare('dissasemble') == 0 || commands[0].compare('disasm') == 0
		|| commands[0].compare('dm') == 0 {
		if commands.len < 2 {
			println(term.red('Invalid number of arguments for dissasemble command.'))
			return true
		}

		// Parsing the address.
		size := i16(strconv.common_parse_int(commands[1], 0, 16, false, false) or {
			println(term.red('Invalid dissasemble size.'))
			return true
		})

		// Dissasemble the instructions.
		for index in -size .. size + 1 {
			target := if index > 0 {
				self.memory.pc + u16(2 * index)
			} else {
				self.memory.pc - u16(-2 * index)
			}
			instruction := self.memory.read2(target)
			println("${if self.memory.pc == target { term.red('>') } else { ' ' }} ${term.gray('0x${target:04X}')}: 0x${instruction:04X} ${term.blue('(${self.disassemble_instruction(instruction)})')}")
		}

		return true
	}

	// Breakpoints.
	if commands[0].compare('break') == 0 || commands[0].compare('b') == 0 {
		if commands.len < 2 {
			println(term.red('Invalid number of arguments for break command.'))
			return true
		}

		// Parsing the address.
		address := u16(strconv.common_parse_int(commands[1], 16, 16, false, false) or {
			println(term.red('Invalid breakpoint address.'))
			return true
		})

		// TODO: implement this.
		println(term.blue('Breakpoint set at address: 0x${address:02X}'))
		return true
	}

	println(term.red('Invalid command.'))
	return true
}
