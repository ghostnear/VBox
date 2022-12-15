module app

import sdl

struct Input
{
pub mut:
	event &sdl.Event = &sdl.Event{}

	// TODO: key bindings and hooks into main app
}

pub fn poll_events(mut app App)
{
	for sdl.poll_event(app.input.event) > 0
	{
		// TODO: more inputs
		match app.input.event.@type
		{
			.quit {
				app.quit()
			}
			else {}
		}
	}
}