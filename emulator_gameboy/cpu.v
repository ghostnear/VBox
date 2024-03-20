module emulator_gameboy

import os
import log

// CPU instruction have been configured into a function pointer to our routines and 2 arguments. Lets hope none of them are longer.
struct Instruction {
	func fn (mut self CPU, arg1 voidptr, arg2 voidptr) = unsafe { nil }
	arg1 voidptr
	arg2 voidptr
}

// WARN: THIS ORDER ASSUMES THAT WE ARE USING LITTLE ENDIANESS

// Registers are marked as packed because, using funny pointers, we can get the 16 bit registers much easier this way.
@[packed]
struct Registers {
mut:
	f u8
	a u8
	c u8
	b u8
	e u8
	d u8
	l u8
	h u8
}

@[heap]
struct CPU {
mut:
	// Refference to the RAM so we can use it.
	ram &RAM
	// "Special registers"
	pc u16
	sp u16
	// Registers are stored here.
	reg Registers
	// Instruction decoding tables.
	rot_table []fn (mut self CPU, arg1 voidptr, arg2 voidptr)
	// Rotation / shift operations.
	alu_table []fn (mut self CPU, arg1 voidptr, arg2 voidptr)
	// Arithmetic / logic operations.
	rp_table []&u16
	//
	rp2_table []&u16
	// 16 bit register tables.
	reg_table []&u8
	// 8 bit register table.
	// For debug logging only.
	debug os.File
}

fn (mut self CPU) log_current_status() {
	// I sure love funny string formatting making my lines long...
	self.debug.writeln('A:${self.reg.a:02X} F:${self.reg.f:02X} B:${self.reg.b:02X} C:${self.reg.c:02X} D:${self.reg.d:02X} E:${self.reg.e:02X} H:${self.reg.h:02X} L:${self.reg.l:02X} SP:${self.sp:04X} PC:${self.pc:04X} PCMEM:${self.ram.read_byte(self.pc):02X},${self.ram.read_byte(
		self.pc + 1):02X},${self.ram.read_byte(self.pc + 2):02X},${self.ram.read_byte(self.pc + 3):02X}') or {}
	self.debug.flush()
}

fn (mut self CPU) init() {
	// Initialize tables.
	unsafe {
		self.rp_table = [&u16(&self.reg.c), &self.reg.e, &self.reg.l, &self.sp]
		self.rp2_table = [&u16(&self.reg.c), &self.reg.e, &self.reg.l, &self.reg.f]
	}
	self.alu_table = [
		instruction_add_to_a,
		instruction_add_with_carry_to_a,
		instruction_sub_from_a,
		instruction_sub_with_carry_from_a,
		instruction_and_with_a,
		instruction_xor_with_a,
		instruction_or_with_a,
		instruction_cp_with_a,
	]
	self.reg_table = [
		&self.reg.b,
		&self.reg.c,
		&self.reg.d,
		&self.reg.e,
		&self.reg.h,
		&self.reg.l,
		0,
		// This is fixed by update_hl_reg()
		&self.reg.a,
	]
	self.rot_table = [
		instruction_cb_rotate_left_carry,
		instruction_cb_rotate_right_carry,
		instruction_cb_rotate_left,
		instruction_cb_rotate_right,
		instruction_cb_shift_left_arithmetic,
		instruction_cb_shift_right_arithmetic,
		instruction_cb_swap,
		instruction_cb_shift_logical_right,
	]
}

// Useful for skipping the boot ROM.
fn (mut self CPU) set_post_boot_state() {
	self.reg.a = 0x01
	self.reg.f = 0xB0
	self.reg.b = 0x00
	self.reg.c = 0x13
	self.reg.d = 0x00
	self.reg.e = 0xD8
	self.reg.h = 0x01
	self.reg.l = 0x4D
	self.sp = 0xFFFE
	self.pc = 0x100
}

@[inline]
fn (mut self CPU) update_hl_reg() {
	unsafe {
		self.reg_table[6] = self.ram.get_pointer(&u16(&self.reg.l))
		self.reg.f &= 0xF0
	}
}

fn (mut self CPU) decode_opcode(opcode u16) Instruction {
	/*
	* The Romanian programmers' book this guy used is here to save us.
	 * https://gb-archive.github.io/salvage/decoding_gbz80_opcodes/Decoding%20Gamboy%20Z80%20Opcodes.html
	*/

	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111
	p := y >> 1
	q := y & 0b1

	match x {
		0 {
			match z {
				0 {
					match y {
						0 {
							return Instruction{
								func: instruction_nop
							}
						}
						1 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							return Instruction{
								func: instruction_ld_16
								arg1: self.ram.get_pointer(data)
								arg2: &self.sp
							}
						}
						2 {
							println('WARN: Unimplemented STOP instruction.')
							return Instruction{
								func: instruction_nop
							}
						}
						3 {
							return Instruction{
								func: instruction_relative_jump
								arg1: self.ram.read_byte(self.pc)
							}
						}
						4...8 {
							data := self.ram.read_byte(self.pc)
							self.pc += 1
							return Instruction{
								func: instruction_conditional_relative_jump
								arg1: y - 4
								arg2: data
							}
						}
						else {}
					}
				}
				1 {
					match q {
						0 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							return Instruction{
								func: instruction_ld_16imm
								arg1: self.rp_table[p]
								arg2: data
							}
						}
						1 {
							return Instruction{
								func: instruction_add_16
								arg1: &self.reg.l
								arg2: self.rp_table[p]
							}
						}
						else {}
					}
				}
				2 {
					match q {
						0 {
							match p {
								0 {
									unsafe {
										return Instruction{
											func: instruction_ld_8
											arg1: self.ram.get_pointer(*&u16(&self.reg.c))
											arg2: &self.reg.a
										}
									}
								}
								1 {
									unsafe {
										return Instruction{
											func: instruction_ld_8
											arg1: self.ram.get_pointer(*&u16(&self.reg.e))
											arg2: &self.reg.a
										}
									}
								}
								2 {
									unsafe {
										hl := &u16(&self.reg.l)
										(*hl)++
										return Instruction{
											func: instruction_ld_8
											arg1: self.ram.get_pointer((*hl) - 1)
											arg2: &self.reg.a
										}
									}
								}
								3 {
									unsafe {
										hl := &u16(&self.reg.l)
										(*hl)--
										return Instruction{
											func: instruction_ld_8
											arg1: self.ram.get_pointer((*hl) + 1)
											arg2: &self.reg.a
										}
									}
								}
								else {}
							}
						}
						1 {
							match p {
								0 {
									unsafe {
										return Instruction{
											func: instruction_ld_8
											arg1: &self.reg.a
											arg2: self.ram.get_pointer(*&u16(&self.reg.c))
										}
									}
								}
								1 {
									unsafe {
										return Instruction{
											func: instruction_ld_8
											arg1: &self.reg.a
											arg2: self.ram.get_pointer(&u16(&self.reg.e))
										}
									}
								}
								2 {
									unsafe {
										hl := &u16(&self.reg.l)
										(*hl)++
										return Instruction{
											func: instruction_ld_8
											arg1: &self.reg.a
											arg2: self.ram.get_pointer((*hl) - 1)
										}
									}
								}
								3 {
									unsafe {
										hl := &u16(&self.reg.l)
										(*hl)--
										return Instruction{
											func: instruction_ld_8
											arg1: &self.reg.a
											arg2: self.ram.get_pointer((*hl) + 1)
										}
									}
								}
								else {}
							}
						}
						else {}
					}
				}
				3 {
					match q {
						0 {
							return Instruction{
								func: instruction_inc_16
								arg1: self.rp_table[p]
							}
						}
						1 {
							return Instruction{
								func: instruction_dec_16
								arg1: self.rp_table[p]
							}
						}
						else {}
					}
				}
				4 {
					return Instruction{
						func: instruction_inc
						arg1: self.reg_table[y]
					}
				}
				5 {
					return Instruction{
						func: instruction_dec
						arg1: self.reg_table[y]
					}
				}
				6 {
					data := self.ram.read_byte(self.pc)
					self.pc += 1
					return Instruction{
						func: instruction_ld_8imm
						arg1: self.reg_table[y]
						arg2: data
					}
				}
				7 {
					match y {
						0 {
							return Instruction{
								func: instruction_rotate_left_carry_a
							}
						}
						1 {
							return Instruction{
								func: instruction_rotate_right_carry_a
							}
						}
						2 {
							return Instruction{
								func: instruction_rotate_left_a
							}
						}
						3 {
							return Instruction{
								func: instruction_rotate_right_a
							}
						}
						4 {
							return Instruction{
								func: instruction_daa
							}
						}
						5 {
							return Instruction{
								func: instruction_cpl
								arg1: &self.reg.a
							}
						}
						6 {
							return Instruction{
								func: instruction_scf
							}
						}
						7 {
							return Instruction{
								func: instruction_ccf
							}
						}
						else {}
					}
				}
				else {}
			}
		}
		1 {
			if z == 6 && y == 6 {
				log.warn('Unimplemented HALT instruction.')
				return Instruction{
					func: instruction_nop
				}
			}
			return Instruction{
				func: instruction_ld_8
				arg1: self.reg_table[y]
				arg2: self.reg_table[z]
			}
		}
		2 {
			return Instruction{
				func: self.alu_table[y]
				arg1: self.reg_table[z]
			}
		}
		3 {
			match z {
				0 {
					match y {
						0...3 {
							return Instruction{
								func: instruction_conditional_ret
								arg1: y
							}
						}
						4 {
							data := self.ram.read_byte(self.pc)
							self.pc += 1
							return Instruction{
								func: instruction_ld_8
								arg1: self.ram.get_pointer(u16(0xFF00) + data)
								arg2: &self.reg.a
							}
						}
						5 {
							data := i8(self.ram.read_byte(self.pc))
							self.pc += 1
							return Instruction{
								func: instruction_add_i8_to_i16
								arg1: &self.sp
								arg2: &data
							}
						}
						6 {
							data := self.ram.read_byte(self.pc)
							self.pc += 1
							return Instruction{
								func: instruction_ld_8
								arg1: &self.reg.a
								arg2: self.ram.get_pointer(u16(0xFF00) + data)
							}
						}
						7 {
							data := i8(self.ram.read_byte(self.pc))
							self.pc += 1

							old_sp := self.sp
							instruction_add_i8_to_i16(mut self, &self.sp, &data)
							self.sp = old_sp

							add_result := (i16(self.sp) + data)
							return Instruction{
								func: instruction_ld_16
								arg1: self.rp_table[2]
								arg2: &add_result
							}
						}
						else {}
					}
				}
				1 {
					match q {
						0 {
							return Instruction{
								func: instruction_pop
								arg1: self.rp2_table[p]
							}
						}
						1 {
							match p {
								0 {
									return Instruction{
										func: instruction_ret
									}
								}
								2 {
									return Instruction{
										func: instruction_direct_jump
										arg1: unsafe { *&u16(&self.reg.l) }
									}
								}
								3 {
									return Instruction{
										func: instruction_ld_16
										arg1: &self.sp
										arg2: unsafe { &u16(&self.reg.l) }
									}
								}
								else {}
							}
						}
						else {}
					}
				}
				2 {
					match y {
						0...3 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							return Instruction{
								func: instruction_conditional_jump
								arg1: y
								arg2: data
							}
						}
						4 {
							return Instruction{
								func: instruction_ld_8
								arg1: self.ram.get_pointer(u16(0xFF00) + self.reg.c)
								arg2: &self.reg.a
							}
						}
						5 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							return Instruction{
								func: instruction_ld_8
								arg1: self.ram.get_pointer(data)
								arg2: &self.reg.a
							}
						}
						6 {
							return Instruction{
								func: instruction_ld_8
								arg1: &self.reg.a
								arg2: self.ram.get_pointer(u16(0xFF00) + self.reg.c)
							}
						}
						7 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							new_data := self.ram.read_word(data)
							return Instruction{
								func: instruction_ld_8
								arg1: &self.reg.a
								arg2: &new_data
							}
						}
						else {}
					}
				}
				3 {
					match y {
						0 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							return Instruction{
								func: instruction_direct_jump
								arg1: data
							}
						}
						6 {
							return Instruction{
								func: instruction_set_interrupts
								arg1: 0
							}
						}
						7 {
							return Instruction{
								func: instruction_set_interrupts
								arg1: 1
							}
						}
						else {}
					}
				}
				4 {
					data := self.ram.read_word(self.pc)
					self.pc += 2
					return Instruction{
						func: instruction_conditional_call
						arg1: y
						arg2: data
					}
				}
				5 {
					match q {
						0 {
							return Instruction{
								func: instruction_push
								arg1: self.rp2_table[p]
							}
						}
						1 {
							match p {
								0 {
									return Instruction{
										func: instruction_call_16_imm
									}
								}
								else {}
							}
						}
						else {}
					}
				}
				6 {
					data := self.ram.read_byte(self.pc)
					self.pc++
					return Instruction{
						func: self.alu_table[y]
						arg1: &data
					}
				}
				else {}
			}
		}
		else {}
	}

	return Instruction{
		func: unknown_opcode
	}
}

fn (mut self CPU) decode_cb_opcode(opcode u16) Instruction {
	// CB opcodes don't care about anything else than those 3.
	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111

	match x {
		0 {
			return Instruction{
				func: self.rot_table[y]
				arg1: self.reg_table[z]
			}
		}
		1 {
			return Instruction{
				func: instruction_cb_test_bit
				arg1: y
				arg2: self.reg_table[z]
			}
		}
		2 {
			return Instruction{
				func: instruction_cb_reset_bit
				arg1: y
				arg2: self.reg_table[z]
			}
		}
		3 {
			return Instruction{
				func: instruction_cb_set_bit
				arg1: y
				arg2: self.reg_table[z]
			}
		}
		else {}
	}

	return Instruction{
		func: unknown_cb_opcode
	}
}

pub fn (mut self CPU) step() {
	// Update tables.
	self.update_hl_reg()

	// Log status before execution if the parameters are set.
	if self.debug.is_opened {
		self.log_current_status()
	}

	// Fetch opcode.
	mut opcode := self.ram.read_byte(self.pc)
	self.pc++

	// Special CB opcode.
	if opcode == 0xCB {
		opcode = self.ram.read_byte(self.pc)
		self.pc++

		instruction := self.decode_cb_opcode(opcode)
		instruction.func(mut self, instruction.arg1, instruction.arg2)
		return
	}

	// Normal opcode
	instruction := self.decode_opcode(opcode)
	instruction.func(mut self, instruction.arg1, instruction.arg2)
}
