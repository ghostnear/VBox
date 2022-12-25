module locale

import strconv

// All locales.
const locales = {
	'en': map_en
	'ro': map_ro
}

// Gets a translated string and formats it using the parameters.
pub fn get_format_string(lang_code string, key string, pt ...voidptr) string {
	return strconv.v_sprintf(get_string(lang_code, key), ...pt)
}

// Gets a translated string from the language code maps.
pub fn get_string(lang_code string, key string) string {
	// Placeholders in case actual string is not found.
	if lang_code !in locale.locales || key !in locale.locales[lang_code] {
		return strconv.v_sprintf('<%s_%s>', lang_code, key)
	}
	return locale.locales[lang_code][key]
}
