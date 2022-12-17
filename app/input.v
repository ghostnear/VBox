module app

import sdl
import utilities as utils

pub struct Input {
pub mut:
	parent &App = unsafe { nil }
	hooks  utils.HookManager
	event  &sdl.Event = &sdl.Event{}
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
	match app.gfx.display_mode {
		// Do it using SDL_Event
		.sdl {
			for sdl.poll_event(app.inp.event) > 0 {
				match app.inp.event.@type {
					// App has been quit (by any means)
					.quit {
						app.quit()
					}
					// Key has been pressed
					.keydown {
						// Get the keycode
						key := unsafe { sdl.KeyCode(app.inp.event.key.keysym.sym) }

						app.inp.key_down(key)
					}
					// Key has been released
					.keyup {
						// Get the keycode
						key := unsafe { sdl.KeyCode(app.inp.event.key.keysym.sym) }

						app.inp.key_up(key)
					}
					else {}
				}
			}
		}
		.terminal {
			// TODO: terminal input.
		}
		// Do nothing
		else {}
	}
}

pub fn new_input(parent &App) &Input {
	v := &Input{
		parent: parent
	}
	return v
}
