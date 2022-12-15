module app

import sdl

struct Input
{
mut:
	hooks map[string]map[string]fn(voidptr)
	event &sdl.Event = &sdl.Event{}
}

[inline]
fn (mut self Input) call_all_hooks(identifier string, args voidptr)
{
	for _, function in self.hooks[identifier]
	{
		function(args)
	}
}

// Adds a hook to be called upon an event occuring.
// ! Be careful to not have overlapping identfiers or inexistent events as those won't be called. !
[inline]
pub fn (mut self Input) add_hook(event string, identifier string, function fn(voidptr))
{
	self.hooks[event][identifier] = function
}

[inline]
pub fn (mut self Input) remove_hook(event string, identifier string)
{
	self.hooks[event].delete(identifier)
}

pub fn (mut self Input) key_down(key sdl.KeyCode)
{
	self.call_all_hooks("key_down", &key)

	// Define global keybinds here.
}

pub fn (mut self Input) key_up(key sdl.KeyCode)
{
	self.call_all_hooks("key_up", &key)

	// Define global keybinds here.
}

pub fn poll_events(mut app App)
{
	for sdl.poll_event(app.input.event) > 0
	{
		// TODO: more inputs
		match app.input.event.@type
		{
			// App has been quit (by any means)
			.quit 
			{
				app.quit()
			}

			// Key has been pressed
			.keydown
			{
				// Get the keycode
				key := unsafe { sdl.KeyCode(app.input.event.key.keysym.sym) }
				
				app.input.key_down(key)
			}

			// Key has been released
			.keyup
			{
				// Get the keycode
				key := unsafe { sdl.KeyCode(app.input.event.key.keysym.sym) }
				
				app.input.key_up(key)
			}

			else {}
		}
	}
}