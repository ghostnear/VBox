module main

import chip8

fn test_draw()
{
	mut vm := chip8.new_vm()
	vm.mem.copy_bytes(
		0x1FE,
		[
			u8(0x00), u8(0x00) // NOP to satisfy the compiler
		]
	)
}