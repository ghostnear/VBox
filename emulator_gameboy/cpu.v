module emulator_gameboy

struct Instruction {
	func fn (mut self CPU, arg1 voidptr, arg2 voidptr) = unsafe { nil }
	arg1 voidptr
	arg2 voidptr
}

// WARN: THIS ORDER ASSUMES THAT WE ARE USING LITTLE ENDIANESS
[packed]
struct Registers {
mut:
	a u8
	f u8
	b u8
	c u8
	d u8
	e u8
	h u8
	l u8
}

enum CPU_CONDITIONS {
	non_zero = 0
	zero
	non_carry
	carry
}

struct CPU {
mut:
	ram &RAM

	pc u16
	sp u16

	reg Registers

	ime bool

	rp_table  []&u16
	rp2_table []&u16
	rot_table []fn (mut self CPU, arg1 voidptr, arg2 voidptr)
	alu_table []fn (mut self CPU, arg1 voidptr, arg2 voidptr)
	reg_table []&u8
}

fn (mut self CPU) init() {
	unsafe {
		self.rp_table = [&u16(&self.reg.b), &self.reg.d, &self.reg.h, &self.sp]
		self.rp2_table = [&u16(&self.reg.b), &self.reg.d, &self.reg.h, &self.reg.a]
	}
	self.alu_table = [
		unknown_opcode,
		unknown_opcode,
		instruction_sub_from_a,
		unknown_opcode,
		unknown_opcode,
		instruction_xor_with_a,
		unknown_opcode,
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
		&self.reg.a,
	]
	self.rot_table = [
		unknown_cb_opcode,
		unknown_cb_opcode,
		instruction_cb_rotate_left,
		unknown_cb_opcode,
		unknown_cb_opcode,
		unknown_cb_opcode,
		unknown_cb_opcode,
		unknown_cb_opcode,
	]
}

fn (mut self CPU) update_hl_reg() {
	unsafe {
		self.reg_table[6] = self.ram.get_pointer(&u16(&self.reg.h))
	}
}

fn (mut self CPU) decode_opcode(opcode u16) Instruction {
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
						3 {
							return Instruction{
								func: instruction_relative_jump
								arg1: self.ram.read_byte(self.pc)
							}
						}
						4...7 {
							return Instruction{
								func: instruction_conditional_relative_jump
								arg1: y - 4
								arg2: self.ram.read_byte(self.pc)
							}
						}
						else {}
					}
				}
				1 {
					match q {
						0 {
							return Instruction{
								func: instruction_ld_16imm
								arg1: self.rp_table[p]
								arg2: self.ram.read_word(self.pc)
							}
						}
						else {}
					}
				}
				2 {
					match q {
						0 {
							match p {
								2 {
									return Instruction{
										func: instruction_ld_hl_p_a
									}
								}
								3 {
									return Instruction{
										func: instruction_ld_hl_m_a
									}
								}
								else {}
							}
						}
						1 {
							match p {
								1 {
									unsafe {
										return Instruction{
											func: instruction_ld_8
											arg1: &self.reg.a
											arg2: self.ram.get_pointer(&u16(&self.reg.d))
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
								arg1: &self.rp_table[p]
							}
						}
						else {}
					}
				}
				4 {
					self.update_hl_reg()
					return Instruction{
						func: instruction_inc
						arg1: self.reg_table[y]
					}
				}
				5 {
					self.update_hl_reg()
					return Instruction{
						func: instruction_dec
						arg1: self.reg_table[y]
					}
				}
				6 {
					self.update_hl_reg()
					return Instruction{
						func: instruction_ld_8imm
						arg1: self.reg_table[p]
						arg2: self.ram.read_byte(self.pc + 1)
					}
				}
				7 {
					match y {
						2 {
							return Instruction{
								func: instruction_cb_rotate_left
								arg1: &self.reg.a
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
				panic('HALT UNIMPLEMENTED')
			}
			return Instruction{
				func: instruction_ld_8
				arg1: self.reg_table[y]
				arg2: self.reg_table[z]
			}
		}
		2 {
			self.update_hl_reg()
			return Instruction{
				func: self.alu_table[y]
				arg1: self.reg_table[z]
			}
		}
		3 {
			match z {
				0 {
					match y {
						4 {
							self.pc += 1
							return Instruction{
								func: instruction_ld_addr_8
								arg1: 0xFF00 + self.ram.read_byte(self.pc)
								arg2: self.reg.a
							}
						}
						6 {
							data := self.ram.read_byte(0xFF00 + self.ram.read_byte(self.pc))
							self.pc += 1
							return Instruction{
								func: instruction_ld_8
								arg1: &self.reg.a
								arg2: &data
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
								else {}
							}
						}
						else {}
					}
				}
				2 {
					match y {
						4 {
							return Instruction{
								func: instruction_ld_addr_8
								arg1: 0xFF00 + self.reg.c
								arg2: self.reg.a
							}
						}
						5 {
							data := self.ram.read_word(self.pc)
							self.pc += 2
							return Instruction{
								func: instruction_ld_addr_8
								arg1: data
								arg2: self.reg.a
							}
						}
						else {}
					}
				}
				3 {
					match y {
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
						func: self.alu_table[y],
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
	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111

	match x {
		0 {
			self.update_hl_reg()
			return Instruction{
				func: self.rot_table[y]
				arg1: self.reg_table[z]
			}
		}
		1 {
			self.update_hl_reg()
			return Instruction{
				func: instruction_cb_test_bit
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
	mut opcode := self.ram.read_byte(self.pc)
	println("${self.pc:04X}")
	self.pc++
	if opcode == 0xCB {
		opcode = self.ram.read_byte(self.pc)
		self.pc++
		instruction := self.decode_cb_opcode(opcode)
		instruction.func(mut self, instruction.arg1, instruction.arg2)
		return
	}
	instruction := self.decode_opcode(opcode)
	instruction.func(mut self, instruction.arg1, instruction.arg2)
}
