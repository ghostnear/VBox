module utilities

import term
import locale

pub fn print_fatal_error(lang_code string, message string)
{
	println("\n" + term.red(term.bold(locale.get_string(lang_code, "message_fatal_error_title")) + message))
	println("\n" + term.italic(term.bold(locale.get_string(lang_code, "message_check_logfile"))) + "\n")
}