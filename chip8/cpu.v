module chip8

// CHIP8 CPU structure.
struct CPU
{
pub mut:
	execution_flag bool
	halt_flag bool

	// Registers
	pc u16
	register []u8
	ir u16
}

// Steps the CPU one instruction in.
pub fn (mut self CPU) step(mut parent &VM)
{
	opcode_value := parent.mem.fetch_word(self.pc)
	self.execute_opcode(opcode_value, mut parent)
}

// Creates a new CPU instance.
[inline]
fn new_cpu() &CPU
{
	cpu := &CPU {
		execution_flag: false
		halt_flag: false
		register: []u8 {len: 0x10, cap: 0x10, init: 0}
		pc: 0x0200
		ir: 0x0000
	}
	return cpu
}