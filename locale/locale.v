module locale

// All locales.
const locales = {
	'en': map_en
	'ro': map_ro
}

// Gets a translated string from the language code maps.
pub fn get_string(lang_code string, key string) string {
	// Placeholders in case actual string is not found.
	if lang_code !in locale.locales || key !in locale.locales[lang_code] {
		return '<' + lang_code + '_' + key + '>'
	}
	return locale.locales[lang_code][key]
}
