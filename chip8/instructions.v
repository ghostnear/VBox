module chip8

import utilities as utils

// Directly executes an encoded opcode.
pub fn (mut self CPU) execute_opcode(opcode u16, mut parent &VM)
{
	// Advance PC
	self.pc += 2
	match (opcode & 0xF000) >> 12
	{
		0x0
		{
			// NOP
			if opcode == 0x0000 {}
		}
		0x1
		{
			// JMP NNN
			self.pc = opcode & 0xFFF
		}
		0x3
		{
			// SE VX, NN
			if self.register[(opcode & 0xF00) >> 8] == opcode & 0xFF
			{
				self.pc += 2
			}
		}
		0x6
		{
			// Vx = 0xNN
			self.register[(opcode & 0xF00) >> 8] = u8(opcode & 0xFF)
		}
		0xA
		{
			// I = 0xNNN
			self.ir = u16(opcode & 0xFFF)
			self.ir &= 0xFFF
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
		else
		{
			println("Unknown instruction at address ${ self.pc:04X }!")
			println("Value of opcode is: ${ opcode:04X }!")
			self.execution_flag = false
		}
	}
}