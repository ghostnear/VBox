module emulator_gameboy

import log
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
	log.error('Unknown CB opcode ${opcode:02X} detected at PC ${self.pc - 2:04X}!')

	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111

	log.warn('Debug data (x: ${x}, y: ${y}, z: ${z})')

	exit(-1)
}

fn unknown_opcode(mut self CPU, arg1 voidptr, arg2 voidptr) {
	opcode := self.ram.read_byte(self.pc - 1)
	log.error('Unknown opcode ${opcode:02X} detected at PC ${self.pc - 1:04X}!')

	x := opcode >> 6
	y := (opcode >> 3) & 0b111
	z := opcode & 0b111
	p := y >> 1
	q := y & 0b1

	log.warn('Debug data (x: ${x}, y: ${y}, z: ${z}, p: ${p}, q: ${q})')

	exit(-1)
}

/// Actual instructions.
fn instruction_add_to_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		set_cpu_flag(mut self, CPU_FLAGS.c, int(0xFF - self.reg.a < *(&u8(arg1))))
		set_cpu_flag(mut self, CPU_FLAGS.h, int((((self.reg.a & 0xf) + (*(&u8(arg1)) & 0xf)) & 0x10) == 0x10))
		self.reg.a += *(&u8(arg1))
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	}
}

fn instruction_add_with_carry_to_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		old_carry := u8(get_cpu_flag(mut self, CPU_FLAGS.c))
		set_cpu_flag(mut self, CPU_FLAGS.h, int((((self.reg.a & 0xF) + (*(&u8(arg1)) & 0xF) +
			u8(get_cpu_flag(mut self, CPU_FLAGS.c))) & 0x10) == 0x10))
		set_cpu_flag(mut self, CPU_FLAGS.c, int(0xFF < int(get_cpu_flag(mut self, CPU_FLAGS.c)) +
			self.reg.a + *(&u8(arg1))))
		self.reg.a += *(&u8(arg1)) + old_carry
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	}
}

fn instruction_sub_from_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		set_cpu_flag(mut self, CPU_FLAGS.c, int(self.reg.a < *(&u8(arg1))))
		set_cpu_flag(mut self, CPU_FLAGS.h, int((self.reg.a & 0xF) < (*(&u8(arg1)) & 0xF)))
		self.reg.a -= *(&u8(arg1))
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 1)
	}
}

fn instruction_sub_with_carry_from_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		old_carry := u8(get_cpu_flag(mut self, CPU_FLAGS.c))
		set_cpu_flag(mut self, CPU_FLAGS.h, int(self.reg.a & 0xF < (*(&u8(arg1)) & 0xF) + old_carry))
		set_cpu_flag(mut self, CPU_FLAGS.c, int(self.reg.a <
			int(get_cpu_flag(mut self, CPU_FLAGS.c)) + *(&u8(arg1))))
		self.reg.a -= *(&u8(arg1)) + old_carry
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 1)
	}
}

fn instruction_and_with_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		self.reg.a &= *(&u8(arg1))
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.c, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 1)
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

fn instruction_daa(mut self CPU, arg1 voidptr, arg2 voidptr) {
	// https://forums.nesdev.org/viewtopic.php?t=15944 (thanks.)
	// note: assumes a is a uint8_t and wraps from 0xff to 0
	if get_cpu_flag(mut self, CPU_FLAGS.n) == 0 {  // after an addition, adjust if (half-)carry occurred or if result is out of bounds
		if get_cpu_flag(mut self, CPU_FLAGS.c) != 0 || self.reg.a > 0x99 {
			self.reg.a += 0x60;
			set_cpu_flag(mut self, CPU_FLAGS.c, 1)
		}
		if get_cpu_flag(mut self, CPU_FLAGS.h) != 0 || (self.reg.a & 0x0f) > 0x09 {
			self.reg.a += 0x6;
		}
	}
	else {  // after a subtraction, only adjust if (half-)carry occurred
		if get_cpu_flag(mut self, CPU_FLAGS.c) != 0 { self.reg.a -= 0x60; }
		if get_cpu_flag(mut self, CPU_FLAGS.h) != 0 { self.reg.a -= 0x6; }
	}
	// these flags are always updated
	set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0)) // the usual z flag
	set_cpu_flag(mut self, CPU_FLAGS.h, 0) // h flag is always cleared
}

fn instruction_or_with_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		self.reg.a |= *(&u8(arg1))
		set_cpu_flag(mut self, CPU_FLAGS.z, int(self.reg.a == 0))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.c, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	}
}

fn instruction_cp_with_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	set_cpu_flag(mut self, CPU_FLAGS.h, int((self.reg.a & 0xF) < (*(&u8(arg1)) & 0xF)))
	result := self.reg.a - *(&u8(arg1))
	set_cpu_flag(mut self, CPU_FLAGS.z, int(result == 0))
	set_cpu_flag(mut self, CPU_FLAGS.n, 1)
	set_cpu_flag(mut self, CPU_FLAGS.c, int(self.reg.a < *(&u8(arg1))))
}

fn instruction_ld_16(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u16(arg1)) = *(&u16(arg2))
	}
}

fn instruction_ld_16imm(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u16(arg1)) = u16(arg2)
	}
}

fn instruction_conditional_jump(mut self CPU, arg1 voidptr, arg2 voidptr) {
	if !check_flag(mut self, arg1) {
		return
	}
	self.pc = u16(arg2)
}

fn instruction_direct_jump(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.pc = u16(arg1)
}

fn instruction_nop(mut self CPU, arg1 voidptr, arg2 voidptr) {
	// Do nothing obviously.
}

fn instruction_ld_8(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u8(arg1)) = *(&u8(arg2))
	}
}

fn instruction_conditional_call(mut self CPU, arg1 voidptr, arg2 voidptr) {
	if !check_flag(mut self, arg1) {
		return
	}
	self.sp -= 2
	self.ram.write_word(self.sp, self.pc)
	self.pc = u16(arg2)
}

fn instruction_add_i8_to_i16(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		// Highly illegal
		set_cpu_flag(mut self, CPU_FLAGS.c, int((((*(&i16(arg1)) & 0xFF) + (*(&i8(arg2)) & 0xFF)) & 0x100) == 0x100))
		set_cpu_flag(mut self, CPU_FLAGS.h, int((((*(&i16(arg1)) & 0xF) + (*(&i8(arg2)) & 0xF)) & 0x10) == 0x10))
		*(&i16(arg1)) += *(&i8(arg2))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, 0)
	}
}

fn instruction_add_8(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		set_cpu_flag(mut self, CPU_FLAGS.c, int(0xFF - *(&u8(arg1)) < *(&u8(arg2))))
		set_cpu_flag(mut self, CPU_FLAGS.h, int((((*(&u8(arg1)) & 0xF) + (*(&u8(arg2)) & 0xF)) & 0x10) == 0x10))
		*(&u8(arg1)) += *(&u8(arg2))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	}
}

fn instruction_add_16(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		set_cpu_flag(mut self, CPU_FLAGS.c, int(0xFFFF - *(&u16(arg1)) < *(&u16(arg2))))
		set_cpu_flag(mut self, CPU_FLAGS.h, int((((*(&u16(arg1)) & 0xFFF) + (*(&u16(arg2)) & 0xFFF)) & 0x1000) == 0x1000))
		*(&u16(arg1)) += *(&u16(arg2))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
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
}

fn instruction_set_interrupts(mut self CPU, arg1 voidptr, arg2 voidptr) {
	self.ram.write_byte(0xFFFF, arg1)
}

fn instruction_inc(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u8(arg1)
	set_cpu_flag(mut self, CPU_FLAGS.h, int((((*addr & 0xf) + (0x01 & 0xf)) & 0x10) == 0x10))
	(*addr)++
	set_cpu_flag(mut self, CPU_FLAGS.z, int(*addr == 0))
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
}

fn instruction_inc_16(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u16(arg1)
	(*addr)++
}

fn instruction_dec_16(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u16(arg1)
	(*addr)--
}

fn check_flag(mut self CPU, flag voidptr) bool {
	match CPU_CONDITIONS(flag) {
		.carry {
			if get_cpu_flag(mut self, CPU_FLAGS.c) == 0 {
				return false
			}
		}
		.non_carry {
			if get_cpu_flag(mut self, CPU_FLAGS.c) != 0 {
				return false
			}
		}
		.zero {
			if get_cpu_flag(mut self, CPU_FLAGS.z) == 0 {
				return false
			}
		}
		.non_zero {
			if get_cpu_flag(mut self, CPU_FLAGS.z) != 0 {
				return false
			}
		}
		else {
			panic('Wrong jump flag: ${flag}')
		}
	}
	return true
}

fn instruction_dec(mut self CPU, arg1 voidptr, arg2 voidptr) {
	addr := &u8(arg1)
	set_cpu_flag(mut self, CPU_FLAGS.h, int((((*addr & 0xf) + (0xFF & 0xf)) & 0x10) != 0x10))
	(*addr)--
	set_cpu_flag(mut self, CPU_FLAGS.z, int(*addr == 0))
	set_cpu_flag(mut self, CPU_FLAGS.n, 1)
}

fn instruction_relative_jump(mut self CPU, arg1 voidptr, arg2 voidptr) {
	old_pc := self.pc - 1
	self.pc += 1 + u16(i16(i8(arg1)))
	if old_pc == self.pc {
		log.warn('Infinite jump detected. Stopping!')
		exit(-1)
	}
}

fn instruction_conditional_relative_jump(mut self CPU, arg1 voidptr, arg2 voidptr) {
	if check_flag(mut self, arg1) == false {
		return
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

fn instruction_conditional_ret(mut self CPU, arg1 voidptr, arg2 voidptr) {
	if check_flag(mut self, arg1) == false {
		return
	}
	instruction_pop(mut self, &self.pc, arg2)
}

fn instruction_ret(mut self CPU, arg1 voidptr, arg2 voidptr) {
	instruction_pop(mut self, &self.pc, arg2)
}

fn instruction_scf(mut self CPU, arg1 voidptr, arg2 voidptr) {
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	set_cpu_flag(mut self, CPU_FLAGS.c, 1)
}

fn instruction_ccf(mut self CPU, arg1 voidptr, arg2 voidptr) {
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	set_cpu_flag(mut self, CPU_FLAGS.c, int(!(get_cpu_flag(mut self, CPU_FLAGS.c) != 0)))
}

fn instruction_cpl(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		*(&u8(arg1)) = ~*(&u8(arg1))
	}
	set_cpu_flag(mut self, CPU_FLAGS.h, 1)
	set_cpu_flag(mut self, CPU_FLAGS.n, 1)
}

fn instruction_rotate_left_carry_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		set_cpu_flag(mut self, CPU_FLAGS.c, utils.get_bit(self.reg.a, 7))
		self.reg.a <<= 1
		utils.set_bit(&self.reg.a, 0, get_cpu_flag(mut self, CPU_FLAGS.c))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, 0)
	}
}

fn instruction_rotate_right_carry_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		set_cpu_flag(mut self, CPU_FLAGS.c, self.reg.a & 1)
		self.reg.a >>= 1
		utils.set_bit(&self.reg.a, 7, get_cpu_flag(mut self, CPU_FLAGS.c))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, 0)
	}
}

fn instruction_rotate_left_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		old_carry := get_cpu_flag(mut self, CPU_FLAGS.c)
		set_cpu_flag(mut self, CPU_FLAGS.c, utils.get_bit(self.reg.a, 7))
		self.reg.a <<= 1
		utils.set_bit(&self.reg.a, 0, old_carry)
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, 0)
	}
}

fn instruction_rotate_right_a(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		old_carry := get_cpu_flag(mut self, CPU_FLAGS.c)
		set_cpu_flag(mut self, CPU_FLAGS.c, self.reg.a & 1)
		self.reg.a >>= 1
		utils.set_bit(&self.reg.a, 7, old_carry)
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, 0)
	}
}

fn instruction_cb_test_bit(mut self CPU, arg1 voidptr, arg2 voidptr) {
	// Set flags and move on
	set_cpu_flag(mut self, CPU_FLAGS.z, int(utils.get_bit(*&u8(arg2), arg1) == 0))
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 1)
}

fn instruction_cb_rotate_left_carry(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		value := &u8(arg1)
		set_cpu_flag(mut self, CPU_FLAGS.c, utils.get_bit(*value, 7))
		*value <<= 1
		utils.set_bit(value, 0, get_cpu_flag(mut self, CPU_FLAGS.c))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, int(*value == 0))
	}
}

fn instruction_cb_rotate_right_carry(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		value := &u8(arg1)
		set_cpu_flag(mut self, CPU_FLAGS.c, (*value) & 1)
		*value >>= 1
		utils.set_bit(value, 7, get_cpu_flag(mut self, CPU_FLAGS.c))
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, int(*value == 0))
	}
}

fn instruction_cb_rotate_left(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		value := &u8(arg1)
		old_carry := get_cpu_flag(mut self, CPU_FLAGS.c)
		set_cpu_flag(mut self, CPU_FLAGS.c, (*value & (1 << 7)) >> 7)
		*value <<= 1
		utils.set_bit(value, 0, old_carry)
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, int(*value == 0))
	}
}

fn instruction_cb_rotate_right(mut self CPU, arg1 voidptr, arg2 voidptr) {
	unsafe {
		value := &u8(arg1)
		old_carry := get_cpu_flag(mut self, CPU_FLAGS.c)
		set_cpu_flag(mut self, CPU_FLAGS.c, (*value) & 1)
		*value >>= 1
		utils.set_bit(value, 7, old_carry)
		set_cpu_flag(mut self, CPU_FLAGS.n, 0)
		set_cpu_flag(mut self, CPU_FLAGS.h, 0)
		set_cpu_flag(mut self, CPU_FLAGS.z, int(*value == 0))
	}
}

fn instruction_cb_shift_logical_right(mut self CPU, arg1 voidptr, arg2 voidptr) {
	set_cpu_flag(mut self, CPU_FLAGS.c, (*&u8(arg1)) & 1)
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	unsafe {
		*(&u8(arg1)) >>= 1
		set_cpu_flag(mut self, CPU_FLAGS.z, int(*(&u8(arg1)) == 0))
	}
}

fn instruction_cb_shift_left_arithmetic(mut self CPU, arg1 voidptr, arg2 voidptr) {
	set_cpu_flag(mut self, CPU_FLAGS.c, (*&u8(arg1)) & (1 << 7) >> 7)
	unsafe {
		*&u8(arg1) <<= 1
	}
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	set_cpu_flag(mut self, CPU_FLAGS.z, int(*&u8(arg1) == 0))
}

fn instruction_cb_shift_right_arithmetic(mut self CPU, arg1 voidptr, arg2 voidptr) {
	set_cpu_flag(mut self, CPU_FLAGS.c, (*&u8(arg1)) & 1)
	unsafe {
		*&i8(arg1) >>= 1
	}
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	set_cpu_flag(mut self, CPU_FLAGS.z, int(*&u8(arg1) == 0))
}

fn instruction_cb_swap(mut self CPU, arg1 voidptr, arg2 voidptr) {
	mut result := u8(0)
	result |= (*&u8(arg1) & 0xF) << 4
	result |= (*&u8(arg1) & 0xF0) >> 4
	(*&u8(arg1)) = result
	set_cpu_flag(mut self, CPU_FLAGS.c, 0)
	set_cpu_flag(mut self, CPU_FLAGS.n, 0)
	set_cpu_flag(mut self, CPU_FLAGS.h, 0)
	set_cpu_flag(mut self, CPU_FLAGS.z, int(result == 0))
}

fn instruction_cb_set_bit(mut self CPU, arg1 voidptr, arg2 voidptr) {
	utils.set_bit(&u8(arg2), arg1, 1)
}

fn instruction_cb_reset_bit(mut self CPU, arg1 voidptr, arg2 voidptr) {
	utils.set_bit(&u8(arg2), arg1, 0)
}
