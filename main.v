module main

import core as app
import emulators.chip8

fn main() {
	// Parse arguments
	mut arg_parser := app.parse_arguments()

	// Instantiate the app.
	mut app_instance := app.new_app(app.fetch_app_config(arg_parser))

	// TODO: (longtime) a 'No Game' screen if the settings wouldn't be set properly for an emulator to run.

	// Instantiate VM using default config.
	mut vm_config := chip8.VMConfig{
		rom_path: 'roms/chip8/games/Pong (1 player).ch8'
	}
	mut chip8_vm := chip8.new_vm(vm_config, mut app_instance)
	chip8_vm.start()

	// Main loop
	for app_instance.is_running() {
		// TODO: do not stop until all threads are finished. Register the threads in the app context instead.
		if _unlikely_(!chip8_vm.wait_for_finish()) {
			break
		}

		// Do all app things.
		app.poll_events(mut app_instance)
		app.draw(mut app_instance)
		app_instance.wait_for_next_frame()
	}

	chip8_vm.destroy()
}
