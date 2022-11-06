module chip8

// Instruction flow tests.

// Memory should be empty, so expected PC after 5 steps should be 0x20A.
fn test_nops()
{
	mut vm := new_vm()
	for index := 0; index < 5; index++
	{
		// This should step only into NOPs
		vm.step_once()
		assert vm.cpu.current_instruction.instruction_type == .instruction_nop
	}
	assert vm.cpu.pc == 0x20A
}