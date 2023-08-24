module main

import sdl_driver

fn main() {
	mut window := sdl_driver.create_window(sdl_driver.WindowConfig{
		title: 'VBox'
		width: 960
		height: 540
	})

	mut emulator := load_emulator('default.json')
	emulator.window = window

	for !window.should_close() {
		// Update stuff.
		window.update()
		emulator.update()

		// Draw stuff.
		window.start_drawing()
		emulator.draw()
		window.end_drawing()
	}

	window.close()
}
