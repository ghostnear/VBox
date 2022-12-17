module app

import sdl
import utilities as utils

pub struct Input {
pub mut:
	hooks utils.HookManager
	event &sdl.Event = &sdl.Event{}
}

pub fn (mut self Input) key_down(key sdl.KeyCode) {
	self.hooks.call_all_hooks('key_down', &key)

	// Define global keybinds here.
}

pub fn (mut self Input) key_up(key sdl.KeyCode) {
	self.hooks.call_all_hooks('key_up', &key)

	// Define global keybinds here.
}

pub fn poll_events(mut app App) {
	for sdl.poll_event(app.input.event) > 0 {
		match app.input.event.@type {
			// App has been quit (by any means)
			.quit {
				app.quit()
			}
			// Key has been pressed
			.keydown {
				// Get the keycode
				key := unsafe { sdl.KeyCode(app.input.event.key.keysym.sym) }

				app.input.key_down(key)
			}
			// Key has been released
			.keyup {
				// Get the keycode
				key := unsafe { sdl.KeyCode(app.input.event.key.keysym.sym) }

				app.input.key_up(key)
			}
			else {}
		}
	}
}
