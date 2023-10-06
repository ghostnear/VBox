module main

import log
import os
import sdl
import sdl_driver

fn main() {
	// Sanity checks.
	if os.args.len < 2 {
		log.error("No config specified in the command line for the emulator.")
		exit(-1)
	}
	log.set_level(.debug)

	// Create emulator
	mut emulator := load_emulator(os.args[1])
	log.info("Emulator set up.")

	// Create window.
	mut window := sdl_driver.create_window(sdl_driver.WindowConfig{
		title: 'VBox'
		width: 960
		height: 540
	})
	emulator.set_window(window)
	log.info("SDL Window was attached to emulator.")

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
					log.debug("Window close event sent.")
				}
				else {}
			}
		}
	}

	// End.
	window.close()
}
