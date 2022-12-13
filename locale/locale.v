module locale

import term

// TODO: make this an actual file-based system.

pub const message_check_logfile = "Check the log file in the executable's path for more info."
pub const message_fatal_error_title = "Fatal error: "
pub const message_unknown_graphics_selected = "Unknown display mode selected!"
pub const message_sdl_could_not_create_window = "Could not create SDL Window!"
pub const message_sdl_could_not_create_renderer = "Could not create SDL Renderer!"

pub fn print_fatal_error(message string)
{
	println("\n" + term.red(term.bold(message_fatal_error_title) + message))
	println("\n" + term.italic(term.bold(message_check_logfile)) + "\n")
}