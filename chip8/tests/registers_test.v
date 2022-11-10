module main

import chip8

fn test_register_operations()
{
	mut vm := chip8.new_vm()
	vm.mem.copy_bytes(
		0x1FE,
		[
			u8(0x00), u8(0x00) // NOP to satisfy the compiler
			0x6A, 0x30 // LD VA, 0x30
			0xA3, 0x33 // LD I, 0x333
			0x3A, 0x30 // SE VA, 0x30
			0x6A, 0x40 // LD VA, 0x40
		]
	)
	vm.step_multiple_times(3)
	assert vm.cpu.register[0xA] == 0x30, 'Wrong value assigned to register!'
	assert vm.cpu.pc == 0x208, 'Did not skip (SE instruction wrong)!'
	assert vm.cpu.ir == 0x333, 'Wrong value assigned to register I!'
}