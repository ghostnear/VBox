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
	test_vm.start()
	for {}
}