import app
import chip8

fn main() {
	// Instantiate app using default config.
	mut config := app.AppConfig{
		gfx_config: app.GraphicsConfig{
			window_title: 'VBox v ' + app.app_version
			display_mode: .sdl
		}
	}
	mut app_instance := app.new_app(config)

	// Instantiate VM using default config.
	mut vm_config := chip8.VMConfig{
		rom_path: 'roms/chip8/games/Pong (1 player).ch8'
	}
	mut chip8_vm := chip8.new_vm(vm_config, mut app_instance)
	chip8_vm.start()

	// Main loop
	for app_instance.is_running() {
		// TODO: do not stop until all threads are finished. Register the threads in the app context.
		if _unlikely_(!chip8_vm.wait_for_finish()) {
			break
		}

		// Do all the app things.
		app.poll_events(mut app_instance)
		app.draw(mut app_instance)
		app_instance.wait_for_next_frame()
	}

	chip8_vm.destroy()
}
