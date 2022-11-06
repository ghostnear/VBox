module chip8

// Enum containing all the available types of instructions
enum InstructionType
{
	instruction_type_unknown = 0
}

// Struct containing all the info about one specific instruction.
struct CPUInstruction
{
pub mut:
	value u16
	instruction_type InstructionType
}

pub fn (mut self CPU) decode_opcode(opcode u16)
{
	self.current_instruction.value = opcode
	match (opcode & 0xF000) >> 12
	{
		0x0
		{

		}
		else
		{
			self.current_instruction.instruction_type = .instruction_type_unknown
		}
	}
}

pub fn (mut self CPU) execute_opcode()
{
	self.pc += 2

	match self.current_instruction.instruction_type
	{
	.instruction_type_unknown
		{
			println("Opcode unknown at PC ${ self.pc:04X }!")
			println("Value: ${ self.current_instruction.value:04X }")
		}
	}
}