module main

import chip8

// Not too much will be tested here as the results should be seen on the actual screen.

fn test_display_operations()
{
	mut vm := chip8.new_vm()
	vm.mem.copy_bytes(
		0x1FE,
		[
			u8(0x00), u8(0x00) // NOP to satisfy the compiler
			0xA2, 0x00 // LD I, 0x200
			0xD3, 0x41 // DRW, V[3], V[4], 1
			0x00, 0xE0 // CLS
		]
	)
	vm.step_multiple_times(2)

	// It's too much to actually check everything so we'll just check if anything has been set.
	mut at_least_one := false
	for x in vm.gfx.buffer
	{
		if x != 0
		{
			at_least_one = true
		}
	}
	assert at_least_one, "Drawing does not work at all!"

	// Everything should be clear.
	vm.step_once()
	for x in vm.gfx.buffer
	{
		assert x == 0, "Display has not been cleared!"
	}
}