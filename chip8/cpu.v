module chip8

// CHIP8 CPU structure.
struct CPU
{
pub mut:
	execution_flag bool
	halt_flag bool
mut:
	pc u16
	rg []u8
}

// Steps the CPU one instruction in.
pub fn (mut self CPU) step(parent &VM)
{
	opcode_value := parent.mem.fetch_word(self.pc)
	self.execute_opcode(opcode_value)
}

// Creates a new CPU instance.
fn new_cpu() &CPU
{
	cpu := &CPU {
		execution_flag: false
		halt_flag: false
		rg: []u8 {len: 0x10, cap: 0x10, init: 0}
		pc: 0x0200
	}
	return cpu
}