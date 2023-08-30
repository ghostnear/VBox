module emulator_gameboy

import utils

// CPU flag positions as bits in the flag register.
enum CPU_FLAGS {
	z = 7
	n = 6
	h = 5
	c = 4
}

// These are all the possible CPU jumping conditions.
// Total has a double role: counting how many of them they are and being the "last condition" which is basically none in this code.
enum CPU_CONDITIONS {
	non_zero = 0
	zero
	non_carry
	carry
	total
}

/// Functions for working with the CPU flags.

[inline]
fn set_cpu_flag(mut self CPU, flag CPU_FLAGS, value int) {
	utils.set_bit(&self.reg.f, int(flag), value)
}

[inline]
fn get_cpu_flag(mut self CPU, flag CPU_FLAGS) int {
	return utils.get_bit(self.reg.f, int(flag))
}

/// Unknown CPU opcodes.

fn unknown_cb_opcode(mut self CPU, arg1 voidptr, arg2 voidptr) {
	opcode := self.ram.read_byte(self.pc - 1)
	println('ERROR: Unknown CB opcode ${opcode:02X} detected at PC ${self.pc - 2:04X}!')

	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111

	println('WARN: Debug data (x: ${x}, y: ${y}, z: ${z})')

	exit(0)
}

fn unknown_opcode(mut self CPU, arg1 voidptr, arg2 voidptr) {
	opcode := self.ram.read_byte(self.pc - 1)
	println('ERROR: Unknown opcode ${opcode:02X} detected at PC ${self.pc - 1:04X}!')

	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111
	p := y >> 1
	q := y & 0b1

	println('WARN: Debug data (x: ${x}, y: ${y}, z: ${z}, p: ${p}, q: ${q})')

	exit(0)
}

/// Actual instructions.

fn instruction_sub_from_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		self.reg.a -= *(&u8(arg1))
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 1)
	}
}

fn instruction_xor_with_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		self.reg.a ^= *(&u8(arg1))
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.c, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	}
}

fn instruction_cp_with_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	result := self.reg.a - *(&u8(arg1))
	set_cpu_flag(mut self, CPU_FLAGS.z, int(result == 0))
	set_cpu_flag(mut self, CPU_FLAGS.n, 1)
	set_cpu_flag(mut self, CPU_FLAGS.c, int(self.reg.a < *(&u8(arg1))))
}

fn instruction_ld_16imm(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u16(arg1)) = u16(arg2)
	}
	self.pc += 2
}

fn instruction_ld_addr_8(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.ram.write_byte(arg1, arg2)
}

fn instruction_ld_8(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u8(arg1)) = *(&u8(arg2))
	}
}

fn instruction_call_16_imm(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.pc += 2
	self.sp -= 2
	self.ram.write_word(self.sp, self.pc)
	self.pc = (u16(self.ram.read_byte(self.pc - 1)) << 8) | self.ram.read_byte(self.pc - 2)
}

fn instruction_ld_8imm(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u8(arg1)) = u8(arg2)
	}
	self.pc += 1
}

fn instruction_ld_hl_m_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		mut hl := &u16(&self.reg.h)
		self.ram.write_byte(*hl, self.reg.a)
		(*hl)--
	}
}

fn instruction_ld_hl_p_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		mut hl := &u16(&self.reg.h)
		self.ram.write_byte(*hl, self.reg.a)
		(*hl)++
	}
}

fn instruction_set_interrupts(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.ram.write_byte(0xFFFF, arg1)
}

fn instruction_inc(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u8(arg1)
	(*addr)++
}

fn instruction_inc_16(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u16(arg1)
	(*addr)++
}

fn instruction_dec(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u8(arg1)
	(*addr)--
	set_cpu_flag(mut self, CPU_FLAGS.z, int(*addr == 0))
	set_cpu_flag(mut self, CPU_FLAGS.n, 1)
}

fn instruction_relative_jump(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.pc += 1 + u16(i16(i8(arg1)))
}

fn instruction_conditional_relative_jump(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.pc += 1
	match CPU_CONDITIONS(arg1) {
		.zero {
			if get_cpu_flag(mut self, CPU_FLAGS.z) != 0 {
				return
			}
		}
		.non_zero {
			if get_cpu_flag(mut self, CPU_FLAGS.z) == 0 {
				return
			}
		}
		else {
			panic('Something went wrong this should not happen.')
		}
	}
	self.pc += u16(i16(i8(arg2)))
}

fn instruction_push(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.sp -= 2
	self.ram.write_word(self.sp, *(&u16(arg1)))
}

fn instruction_pop(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u16(arg1)) = self.ram.read_word(self.sp)
	}
	self.sp += 2
}

fn instruction_ret(mut self CPU, arg1 voidptr, arg2 voidptr) {
	instruction_pop(mut self, &self.pc, arg2)
}

fn instruction_cb_rotate_left(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		value := &u8(arg1)
		old_carry := utils.get_bit(self.reg.f, int(CPU_FLAGS.c))
		utils.set_bit(&self.reg.f, int(CPU_FLAGS.c), (*value & (1 << 7)) >> 7)
		*value <<= 1
		utils.set_bit(value, 0, old_carry)
	}
}

fn instruction_cb_test_bit(mut self CPU, arg1 voidptr, arg2 voidptr) {
	// Set flags and move on
	set_cpu_flag(mut self, CPU_FLAGS.z, utils.get_bit(*&u8(arg2), arg1))
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 1)
}
