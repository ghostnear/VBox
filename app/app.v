module app
import chip8

struct App
{

}

pub fn new() &App
{
	a := &App {

	}
	return a
}

pub fn(self &App) start()
{
	mut test_vm := chip8.new_vm()
	//test_vm.load_rom('roms/tests/test_opcode.ch8')
	test_vm.start()
	for {
		test_vm.wait_for_finish()
		if !test_vm.cpu.execution_flag
		{
			break
		}
	}
}