module main

import chip8

fn test_jumps()
{
	mut vm := chip8.new_vm()
	vm.mem.copy_bytes(
		0x1FE,
		[
			u8(0x00), u8(0x00) // NOP to satisfy the compiler
			0x12, 0x04 // JMP 0x0204
			0x12, 0x30 // JMP 0x0230
			0x14, 0x60 // JMP 0x0460
		]
	)
	vm.step_once()
	assert vm.cpu.pc == 0x204, 'Jumped to the wrong address!'

	vm.step_once()
	assert vm.cpu.pc == 0x460, 'Jumped to the wrong address!'
}