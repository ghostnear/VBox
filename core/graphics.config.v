module core

pub enum DisplayMode {
	other
	terminal
	sdl
}

const displays_from_string = {
	'terminal': DisplayMode.terminal
	'sdl':      DisplayMode.sdl
}

pub fn (mut self DisplayMode) get_from_string(input string) {
	if input in core.displays_from_string {
		self = core.displays_from_string[input]
	}
}

pub struct GraphicsConfig {
pub mut:
	width        int         = 640
	height       int         = 320
	window_title string      = '<window_title>'
	display_mode DisplayMode = .other
}
