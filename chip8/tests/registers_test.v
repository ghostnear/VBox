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
			0x4A, 0x40 // SNE VA, 0x40
			0x6A, 0x60 // LD VA, 0x60
			0xA2, 0x00 // LD I, 0x200
			0xF1, 0x65 // LD V1, [I]
			0x50, 0x10 // SE V[0], V[1]
			0xA4, 0x00 // LD I, 0x400			
		]
	)
	vm.step_multiple_times(3)
	assert vm.cpu.register[0xA] == 0x30, 'Wrong value assigned to register!'
	assert vm.cpu.pc == 0x208, 'Did not skip (SE instruction wrong)!'
	assert vm.cpu.ir == 0x333, 'Wrong value assigned to register I!'
	vm.step_multiple_times(1)
	assert vm.cpu.pc == 0x20C, 'Did not skip (SNE instruction wrong)!'
	assert vm.cpu.register[0xA] == 0x30, 'Wrong value assigned to register!'
	vm.step_multiple_times(2)
	assert vm.cpu.pc == 0x210, 'PC has wrong value!'
	assert vm.cpu.ir == 0x200, 'I has wrong value!'
	assert vm.cpu.register[0x0] == 0x6A, 'Wrong value assigned to register!'
	assert vm.cpu.register[0x1] == 0x30, 'Wrong value assigned to register!'
	vm.step_multiple_times(2)
	assert vm.cpu.pc == 0x214, 'Jumped when not supposed to!'
	assert vm.cpu.ir == 0x400, 'Jumped when not supposed to!'
}