module main

import os
import sdl
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
	emulator.set_window(window)

	// Event polling stuff
	mut event := sdl.Event{}

	// Main loop.
	for !window.should_close() {
		// Update
		window.update()
		emulator.update()

		// Draw
		window.start_drawing()
		emulator.draw()
		window.end_drawing()

		// Poll events
		for 0 < sdl.poll_event(&event) {
			emulator.on_event(&event)
			match event.@type {
				.quit {
					window.close()
				}
				else {}
			}
		}
	}

	window.close()
}
