import app
import time
import chip8

fn main()
{
	// BIG TODO: abstracticize everything so it is all nice and neat.

	// Instantiate app using default config.
	mut config := app.AppConfig {
		gfx_config: app.GraphicsConfig {
			window_title: "VBox v " + app.app_version 
			display_mode: .terminal
		}
	}
	mut app_instance := app.new_app(config)

	// Instantiate VM using default config.
	mut vm_config := chip8.VMConfig {
		rom_path: 'roms/chip8/games/Pong 2 (Pong hack) [David Winter, 1997].ch8'
	}
	mut chip8_vm := chip8.new_vm(vm_config, app_instance)

	// Start the emulation thread and wait for it to finish.
	chip8_vm.start()

	// Main loop
	for app_instance.is_running()
	{
		// TODO: do not stop until all threads are finished. Register the threads in the app context.
		if _unlikely_(!chip8_vm.wait_for_finish())
		{
			break
		}

		// Do input.
		app.poll_events(mut app_instance)

		// Update 60 times a second just to be sure.
		// TODO: this thing should have an actual update time, depending on the UI type. Or configurable.
		time.sleep(1e+9 / 60.0)
	}
}