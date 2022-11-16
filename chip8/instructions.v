module chip8

import utilities as utils

// UNKWN
[inline]
fn unknown_opcode(mut self &CPU, opcode u16, mut parent &VM)
{
	println("Fatal Error:")
	println("Unknown instruction at address ${ self.pc - 2:04X }!")
	println("Value of opcode is: ${ opcode:04X }!")
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
	}
	for index := 0; index < 0x100; index++
	{
		self.special_table.insert(index, unknown_opcode)
		self.system_table.insert(index, unknown_opcode)
	}

	/*
		All instructions (based on their start)
	*/

	// JMP NNN
	self.instruction_table[0x1] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
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

	// Vx = 0xNN
	self.instruction_table[0x6] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.register[(opcode & 0xF00) >> 8] = u8(opcode & 0xFF)
	}

	// I = 0xNNN
	self.instruction_table[0xA] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.ir = u16(opcode & 0xFFF)
		self.ir &= 0xFFF
	}

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

	// Send to the special opcodes table
	self.instruction_table[0xF] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		self.special_table[opcode & 0xFF](self, opcode, parent)
	}

	/*
		System instructions (start with 0x00)
	*/

	// NOP
	self.system_table[0x000] = fn(mut self &CPU, opcode u16, mut parent &VM) {}

	// CLS
	self.system_table[0x0E0] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		parent.gfx.clear()
	}

	/*
		Special instructions (start with 0xF)
	*/

	// V0...Vx = [I]
	self.special_table[0x65] = fn(mut self &CPU, opcode u16, mut parent &VM)
	{
		for index := 0; index <= (opcode & 0xF00) >> 8; index++
		{
			self.register[index] = parent.mem.fetch_byte(u16(self.ir + index))
		}
	}
}

// Directly executes an encoded opcode.
[inline]
pub fn (mut self CPU) execute_opcode(opcode u16, mut parent &VM)
{
	// Advance PC
	self.pc += 2
	self.instruction_table[(opcode & 0xF000) >> 12](self, opcode, parent)
	/*
	0x5
	{
		// SE VX, VY
		if opcode & 0xF == 0x0
		{
			if self.register[(opcode & 0xF00) >> 8] == self.register[(opcode & 0xF0) >> 4]
			{
				self.pc += 2
			}
		}
		else
		{
			println("Unknown instruction at address ${ self.pc:04X }!")
			println("Value of opcode is: ${ opcode:04X }!")
			self.execution_flag = false				
		}
	}
	0xD
	{
		// DRW VX, VY, N
		// Display N-byte sprite starting at memory location I at (VX, VY).
		// Each set bit is xored with what's already drawn. VF is set to 1 if a collision occurs, 0 otherwise.
		self.register[0xF] = 0
		parent.gfx.draw_flag = true
		for current_index := 0; current_index < opcode & 0xF; current_index++
		{
			current_value := parent.mem.fetch_byte(u16(current_index + self.ir))
			for inside_index := 0; inside_index < 8; inside_index++
			{
				if (current_value & (1 << inside_index)) != 0
				{
					collision := parent.gfx.xor_pixel(utils.Vec2<int>{
						x: self.register[(opcode & 0xF00) >> 8] + inside_index
						y: self.register[(opcode & 0xF0) >> 4] + current_index
					})
					if collision && self.register[0xF] == 0
					{
						self.register[0xF] = 1
					}
				}
			}
		}
	}
	*/
}