module core

import sdl
import utilities as utils

[heap]
pub struct Input {
pub mut:
	parent &App = unsafe { nil }
	hooks  utils.HookManager
	event  &sdl.Event = &sdl.Event{}
}

pub fn (mut self Input) key_down(key sdl.KeyCode) {
	self.hooks.call_all_hooks('key_down', &key)

	// NOTE: Define global keybinds here if needed.
}

pub fn (mut self Input) key_up(key sdl.KeyCode) {
	self.hooks.call_all_hooks('key_up', &key)

	//  NOTE: Define global keybinds here if needed.
}

pub fn (mut app App) poll_events() {
	match app.gfx.display_mode {
		// Do it using SDL_Event
		.sdl {
			for sdl.poll_event(app.inp.event) > 0 {
				// TODO: more event types.
				match app.inp.event.@type {
					// App has been quit (by any means)
					.quit {
						app.quit()
					}
					// Key has been pressed.
					.keydown {
						key := unsafe { sdl.KeyCode(app.inp.event.key.keysym.sym) }
						app.inp.key_down(key)
					}
					// Key has been released.
					.keyup {
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

// Create an input instance using the provided configuration.
// TODO: add a config for things like controller sensitivity and other stuff in the future.
pub fn new_input(parent &App) &Input {
	v := &Input{
		parent: parent
	}
	return v
}
