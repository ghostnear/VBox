module chip8

import rand

// UNKWN
[inline]
fn unknown_opcode(mut self &CPU, opcode u16, mut parent &VM)
{
	self.pc -= 2
	println("Fatal Error:")
	println("Unknown instruction at address ${ self.pc:04X }!")
	println("Value of opcode is: ${ opcode:04X }!")
	// TODO: use the logs for this.
	self.execution_flag = false
}

// Generates the instruction table.
[inline]
fn (mut self CPU) generate_execution_table()
{
	// Empty tables at first.
	for index := 0; index < 0x10; index++
	{
		self.instruction_table.insert(index, unknown_opcode)
		self.arithmetic_table.insert(index, unknown_opcode)
		self.register_ops_table.insert(index, unknown_opcode)
	}
	for index := 0; index < 0x100; index++
	{
		self.keyboard_instruction_table.insert(index, unknown_opcode)
		self.special_table.insert(index, unknown_opcode)
		self.system_table.insert(index, unknown_opcode)
	}

	/*
		All instructions (based on their start)
	*/

	// Send to the system opcodes table
	self.instruction_table[0x0] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		// All opcodes start with 0x00
		if opcode & 0xF00 != 0
		{
			unknown_opcode(mut self, opcode, mut parent)
		}
		else
		{
			self.system_table[opcode & 0xFF](self, opcode, parent)
		}
	}

	// JMP NNN
	self.instruction_table[0x1] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		if self.pc == opcode & 0xFFF + 2
		{
			println("Warning:")
			println("Found infinite jump at address ${ self.pc - 2:04X }!")
			println("Pausing execution!")
			self.halt_flag = true
			// TODO: also use the logs for this.
		}

		self.pc = opcode & 0xFFF
	}
	
	// CALL NNN
	self.instruction_table[0x2] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.sp += 1
		self.stack[self.sp] = self.pc
		self.pc = opcode & 0xFFF
	}

	// SE VX, NN
	self.instruction_table[0x3] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		if self.register[(opcode & 0xF00) >> 8] == opcode & 0xFF
		{
			self.pc += 2
		}
	}

	// SNE VX, NN
	self.instruction_table[0x4] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		if self.register[(opcode & 0xF00) >> 8] != opcode & 0xFF
		{
			self.pc += 2
		}
	}

	// Send to the register operations table
	self.instruction_table[0x5] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register_ops_table[opcode & 0xF](self, opcode, parent)
	}

	// LD VX, NN	
	self.instruction_table[0x6] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] = u8(opcode & 0xFF)
	}

	// ADD VX, NN
	self.instruction_table[0x7] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] += u8(opcode & 0xFF)
	}

	// Send to the register arithmetic table
	self.instruction_table[0x8] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.arithmetic_table[opcode & 0xF](self, opcode, parent)
	}

	// SNE VX, VY
	self.instruction_table[0x9] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		// All opcodes start with 0x0
		if opcode & 0xF != 0
		{
			unknown_opcode(mut self, opcode, mut parent)
		}
		else
		{
			if self.register[(opcode & 0xF00) >> 8] != self.register[(opcode & 0xF0) >> 4]
			{
				self.pc += 2
			}
		}
	}

	// LD I, NNN
	self.instruction_table[0xA] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.ir = u16(opcode & 0xFFF)
		self.ir &= 0xFFF
	}

	// RND VX, NN
	self.instruction_table[0xC] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] = u8(u16(rand.i16()) & (opcode & 0xFF))
	}

	// DRW VX, VY, N
	// Display N-byte sprite starting at memory location I at (VX, VY).
	// Each set bit is xored with what's already drawn. VF is set to 1 if a collision occurs, 0 otherwise.
	self.instruction_table[0xD] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[0xF] = 0
		for current_index := 0; current_index < opcode & 0xF; current_index++
		{
			current_value := parent.mem.fetch_byte(u16(current_index + self.ir))
			for inside_index := 0; inside_index < 8; inside_index++
			{
				if (current_value & (1 << (7 - inside_index))) != 0
				{
					parent.gfx.draw_flag = true
					if parent.gfx.xor_pixel(
						self.register[(opcode & 0xF00) >> 8] + inside_index,
						self.register[(opcode & 0xF0) >> 4] + current_index) == 1
							{
								self.register[0xF] = 1
							}
				}
			}
		}
	}

	// Send to the keyboard opcode stable
	self.instruction_table[0xE] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.keyboard_instruction_table[opcode & 0xFF](self, opcode, parent)
	}

	// Send to the special opcodes table
	self.instruction_table[0xF] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.special_table[opcode & 0xFF](self, opcode, parent)
	}

	/*
		System instructions (start with 0x00)
	*/

	// CLS
	self.system_table[0x0E0] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		parent.gfx.clear()
	}

	// RET
	self.system_table[0x0EE] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.pc = self.stack[self.sp]
		self.sp -= 1
	}

	/*
		Keyboard instructions (start with 0xE)
	*/

	// SKP VX
	self.keyboard_instruction_table[0x9E] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		if parent.inp.is_pressed(self.register[(opcode & 0xF00) >> 8])
		{
			self.pc += 2
		}
	}

	// SKNP VX
	self.keyboard_instruction_table[0xA1] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		if !parent.inp.is_pressed(self.register[(opcode & 0xF00) >> 8])
		{
			self.pc += 2
		}
	}

	/*
		Register instructions (start with 0x5)
	*/
	
	// SE VX, VY
	self.register_ops_table[0x0] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		if self.register[(opcode & 0xF00) >> 8] == self.register[(opcode & 0xF0) >> 4]
		{
			self.pc += 2
		}
	}

	/*
		Register arithmetic instructions (start with 0x8)
	*/

	// LD VX, VY
	self.arithmetic_table[0x0] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] = self.register[(opcode & 0xF0) >> 4]
	}

	// OR VX, VY
	self.arithmetic_table[0x1] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] |= self.register[(opcode & 0xF0) >> 4]
	}

	// AND VX, VY
	self.arithmetic_table[0x2] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] &= self.register[(opcode & 0xF0) >> 4]
	}

	// XOR VX, VY
	self.arithmetic_table[0x3] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] ^= self.register[(opcode & 0xF0) >> 4]
	}

	// ADD VX, VY
	self.arithmetic_table[0x4] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[0xF] = 0x1
		old_vx := self.register[(opcode & 0xF00) >> 8]
		self.register[(opcode & 0xF00) >> 8] += self.register[(opcode & 0xF0) >> 4]
		if self.register[(opcode & 0xF00) >> 8] < old_vx
		{
			self.register[0xF] = 1
		}
	}

	// SUB VX, VY
	self.arithmetic_table[0x5] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[0xF] = 0x1
		old_vx := self.register[(opcode & 0xF00) >> 8]
		self.register[(opcode & 0xF00) >> 8] -= self.register[(opcode & 0xF0) >> 4]
		if self.register[(opcode & 0xF00) >> 8] > old_vx
		{
			self.register[0xF] = 1
		}
	}

	// SHR VX, VY
	self.arithmetic_table[0x6] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[0xF] = self.register[(opcode & 0xF00) >> 8] & 1
		self.register[(opcode & 0xF00) >> 8] >>= 1
	}

	// SHL VX, VY
	self.arithmetic_table[0xE] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[0xF] = self.register[(opcode & 0xF00) >> 8] & 0b10000000
		self.register[(opcode & 0xF00) >> 8] <<= 1
	}

	/*
		Special instructions (start with 0xF)
	*/

	// LD Vx, DT
	self.special_table[0x07] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] = parent.tim.dt
	}

	// LD DT, VX
	self.special_table[0x15] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		parent.tim.dt = self.register[(opcode & 0xF00) >> 8]
	}

	// ADD I, VX
	self.special_table[0x1E] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[0xF] = 0
		self.ir += self.register[(opcode & 0xF00) >> 8]
		if self.ir > 0xFFF
		{
			self.register[0xF] = 1
		}
	}

	// 	BCD VX
	self.special_table[0x33] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		parent.mem.copy_bytes(
			self.ir,
			[
				self.register[(opcode & 0xF00) >> 8] / 100,
				(self.register[(opcode & 0xF00) >> 8] / 10) % 10,
				self.register[(opcode & 0xF00) >> 8] % 10
			]
		)
	}

	// LD [I], Vx
	self.special_table[0x55] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		parent.mem.copy_bytes(
			self.ir,
			self.register[..((opcode & 0xF00) >> 8)]
		)
	}

	// LD VX, [I]
	self.special_table[0x65] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		for index := 0; index <= (opcode & 0xF00) >> 8; index++
		{
			self.register[index] = parent.mem.fetch_byte(u16(self.ir + index))
		}
	}
}