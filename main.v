module main

import core as app
import emulators.chip8

fn main() {
	// Parse arguments
	mut arg_parser := app.parse_arguments()

	// Instantiate the app.
	mut app_instance := app.new_app(app.fetch_app_config(arg_parser))

	// TODO: (longtime) a 'No Game' screen if the settings wouldn't be set properly for an emulator to run.

	// Instantiate the VM.
	// TODO: make this general purpose somehow.
	mut vm := chip8.new_vm(chip8.fetch_vm_config(arg_parser), mut app_instance)
	vm.start()

	// Main loop
	for app_instance.is_running() {
		// TODO: do not stop until all threads are finished. Register the threads in the app context instead.
		if _unlikely_(!vm.wait_for_finish()) {
			break
		}

		// Do all app things.
		app_instance.poll_events()
		app_instance.draw()
		app_instance.wait_for_next_frame()
	}
}
