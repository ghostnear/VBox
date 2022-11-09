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
	}
	assert vm.cpu.pc == 0x20A, 'Flow incorrect when going trough NOPs!'
}

fn test_jumps()
{
	mut vm := new_vm()
	vm.mem.copy_bytes(
		0x200,
		[
			u8(0x00), u8(0x00) // NOP to satisfy the compiler
			0x12, 0x06 // JMP 0x0206
			0x12, 0x30 // JMP 0x0230
			0x14, 0x60 // JMP 0x0460
		]
	)
	vm.step_once()
	vm.step_once()
	assert vm.cpu.pc == 0x206, 'Jumped to the wrong address!'

	vm.step_once()
	assert vm.cpu.pc == 0x460, 'Jumped to the wrong address!'
}

fn test_reg_ops()
{
	mut vm := new_vm()
	vm.mem.copy_bytes(
		0x200,
		[
			u8(0x00), u8(0x00) // NOP to satisfy the compiler
			0x6A, 0x30 // LD VA, 0x30
		]
	)
	vm.step_once()
	vm.step_once()
	assert vm.cpu.rg[0xA] == 0x30, 'Wrong value assigned to register!'
}