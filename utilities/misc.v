module utilities

import sdl
import term
import locale

// Prints a nicely-formatted error to the terminal output.
[inline]
pub fn print_fatal_error(lang_code string, message string) {
	println('\n' +
		term.red(term.bold(locale.get_format_string(lang_code, 'message_fatal_error_title', message))))
	println('\n' + term.italic(term.bold(locale.get_string(lang_code, 'message_check_logfile'))) +
		'\n')
}

// If an SDL error occured, return it as a vstring.
[inline]
pub fn get_sdl_error() string {
	unsafe {
		return cstring_to_vstring(sdl.get_error())
	}
}
