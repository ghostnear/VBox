module chip8

// Enum containing all the available types of instructions
enum InstructionType
{
	instruction_type_unknown = 0
	instruction_nop
	instruction_jmp
	instruction_set_register_constant
	instruction_test
}

// Struct containing all the info about one specific instruction.
struct CPUInstruction
{
pub mut:
	value u16
	instruction_type InstructionType
}

// Decodes an opcode value and saves it as the current instruction.
pub fn (mut self CPU) decode_opcode(opcode u16)
{
	self.current_instruction.value = opcode
	match (opcode & 0xF000) >> 12
	{
		0x0
		{
			// NOP
			if opcode == 0x0000
			{
				self.current_instruction.instruction_type = .instruction_nop
			}
		}
		0x1
		{
			// JMP NNN
			self.current_instruction.instruction_type = .instruction_jmp
		}
		0x6
		{
			// Vx = 0xNN
			self.current_instruction.instruction_type = .instruction_set_register_constant
		}
		else
		{
			self.current_instruction.instruction_type = .instruction_type_unknown
		}
	}
}

// Executes exactly one instruction AFTER it was fetched and decoded.
pub fn (mut self CPU) execute_opcode()
{
	// Advance PC
	self.pc += 2

	match self.current_instruction.instruction_type
	{
	.instruction_nop
		{
			// Do nothing of course.
		}
	.instruction_jmp
		{
			// JMP NNN
			self.pc = self.current_instruction.value & 0xFFF
		}
	.instruction_set_register_constant
		{
			// Vx = 0xNN
			self.rg[(self.current_instruction.value & 0xF00) >> 8] = u8(self.current_instruction.value & 0xFF)
		}
	.instruction_type_unknown
		{
			// Revert changes, stop and print output.
			self.pc -= 2
			println("Unknown opcode at address ${ self.pc:04X }!")
			println("Value: ${ self.current_instruction.value:04X }.")
			self.execution_flag = false
		}
	else
		{
			// Revert changes, stop and print output.
			self.pc -= 2
			println("Opcode unimplemented at address ${ self.pc:04X }!")
			println("Value: ${ self.current_instruction.value:04X }")
			println("Type: ${ self.current_instruction.instruction_type }.")
			self.execution_flag = false
		}
	}
}