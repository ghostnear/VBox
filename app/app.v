module app

import chip8
import time
import term

struct App
{

}

[inline]
pub fn new_app() &App
{
	a := &App {}
	return a
}

pub fn(self &App) start()
{
	// Create new CHIP8 VM and force load the test rom for now.
	// TODO: not do this...
	term.clear()
	mut test_vm := chip8.new_vm()
	test_vm.load_rom('roms/chip8/games/Tetris [Fran Dachille, 1991].ch8')

	// Start the emulation thread and wait for it to finish.
	test_vm.start()
	for
	{
		if !test_vm.wait_for_finish()
		{
			break
		}

		// Update 60 times a second just to be sure.
		// TODO: this thing should have an actual update time, depending on the UI type.
		time.sleep(1e+9 / 60.0)
	}
}