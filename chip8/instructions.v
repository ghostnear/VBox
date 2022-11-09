module chip8

// Directly executes an encoded opcode.
pub fn (mut self CPU) execute_opcode(opcode u16)
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
		0x6
		{
			// Vx = 0xNN
			self.rg[(opcode & 0xF00) >> 8] = u8(opcode & 0xFF)
		}
		else
		{
			println("Unknown instruction at address ${ self.pc:04x }!")
			println("Value of opcode is: ${ opcode:04x }!")
			self.execution_flag = false
		}
	}
}