import app
import time
import chip8

fn main()
{
	// Config for app info.
	mut config := app.AppConfig {}
	config.gfx_config.display_mode = .sdl

	// App instantiation
	mut app_instance := app.new_app(config)

	// Create new CHIP8 VM and force load the test rom for now.
	// TODO: not do this...
	mut test_vm := chip8.new_vm()
	test_vm.load_rom('roms/chip8/games/ZeroPong [zeroZshadow, 2007].ch8')

	// Start the emulation thread and wait for it to finish.
	test_vm.start()
	for app_instance.is_running()
	{
		if !test_vm.wait_for_finish()
		{
			break
		}

		app.poll_events(mut app_instance)

		// Update 60 times a second just to be sure.
		// TODO: this thing should have an actual update time, depending on the UI type.
		time.sleep(1e+9 / 60.0)
	}
}