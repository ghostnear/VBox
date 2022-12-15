module chip8

// CHIP8 CPU structure.
[heap]
struct CPU
{
pub mut:
	execution_flag bool
	halt_flag bool

	// Instruction tables for easier lookups.
	keyboard_instruction_table []fn(&CPU, u16, &VM)
	register_ops_table []fn(&CPU, u16, &VM)
	instruction_table []fn(&CPU, u16, &VM)
	arithmetic_table []fn(&CPU, u16, &VM)
	special_table []fn(&CPU, u16, &VM)
	system_table []fn(&CPU, u16, &VM)

	// Registers
	pc u16
	register []u8
	ir u16

	// Stack
	sp u8
	stack []u16
}

// Steps the CPU one instruction in.
pub fn (mut self CPU) step(mut parent &VM)
{
	opcode_value := parent.mem.fetch_word(self.pc)
	self.execute_opcode(opcode_value, mut parent)
}

// Directly executes an encoded opcode.
[inline]
pub fn (mut self CPU) execute_opcode(opcode u16, mut parent &VM)
{
	// Advance PC
	self.pc += 2
	self.instruction_table[(opcode & 0xF000) >> 12](self, opcode, parent)
}

// Creates a new CPU instance.
[inline]
fn new_cpu() &CPU
{
	// TODO: CPU config
	mut cpu := &CPU {
		execution_flag: false
		halt_flag: false
		stack: []u16{len: 0x10, cap: 0x10, init: 0}
		register: []u8 {len: 0x10, cap: 0x10, init: 0}
		pc: 0x0200
		ir: 0x0000
		sp: 0x00
	}
	cpu.generate_execution_table()
	return cpu
}