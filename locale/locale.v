module locale

import term

// All locales.
const locales = {
	"en": map_en
	"ro": map_ro
}

// Gets a translated string from the language code maps.
pub fn get_string(lang_code string, key string) string
{
	// Placeholders.
	if !(lang_code in locales) || !(key in locales[lang_code])
	{
		return "<" + lang_code + "_" + key + ">"
	}
	return locales[lang_code][key]
}

pub fn print_fatal_error(lang_code string, message string)
{
	println("\n" + term.red(term.bold(get_string(lang_code, "message_fatal_error_title")) + message))
	println("\n" + term.italic(term.bold(get_string(lang_code, "message_check_logfile"))) + "\n")
}