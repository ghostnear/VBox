module main

import chip8

fn test_nop_instructions()
{
	// Memory should be empty, so expected PC after 5 steps should be 0x20A.
	mut vm := chip8.new_vm()

	// This should step only into NOPs
	vm.step_multiple_times(5)
	assert vm.cpu.pc == 0x20A, 'Flow incorrect when going trough NOPs!'
}