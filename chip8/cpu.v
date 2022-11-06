module chip8

// CHIP8 CPU structure.
struct CPU
{
pub mut:
	execution_flag bool
	halt_flag bool
	current_instruction CPUInstruction
mut:
	pc u16
}

// Steps the CPU one instruction in.
pub fn (mut self CPU) step(parent &VM)
{
	opcode_value := parent.mem.fetch_word(self.pc)
	self.decode_opcode(opcode_value)
	self.execute_opcode()
}

// Creates a new CPU instance.
fn new_cpu() &CPU
{
	cpu := &CPU {
		execution_flag: false
		halt_flag: false
		pc: 0x0200
	}
	return cpu
}