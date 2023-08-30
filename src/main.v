module main

import os
import sdl_driver

fn main() {
	// Create window.
	mut window := sdl_driver.create_window(sdl_driver.WindowConfig{
		title: 'VBox'
		width: 960
		height: 540
	})

	// Create emulator
	mut emulator := load_emulator(os.args[1])
	emulator.window = window

	// Main loop.
	for !window.should_close() {
		window.update()
		emulator.update()

		window.start_drawing()
		emulator.draw()
		window.end_drawing()
	}

	window.close()
}
