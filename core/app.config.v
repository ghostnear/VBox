module core

// Struct that helps create the app.
pub struct AppConfig {
pub mut:
	gfx_config GraphicsConfig = GraphicsConfig{
		window_title: 'VBox ' + app_version
		display_mode: .other
	}
}

// TODO: make everything configurable from the command line.
// TODO: later make everything configurable from a config json as well.

/*
* 	Builds the app config from all data sources.
*	ex. args, config files, etc.
*/
pub fn fetch_app_config(arg_parser &ArgParser) AppConfig {
	// Initialize the config with the default settings.
	mut result := AppConfig{
		gfx_config: GraphicsConfig{
			window_title: 'VBox v ' + app_version
			display_mode: .sdl
		}
	}

	// Check for variations in the arguments.
	if arg_parser.is_set('display-mode') {
		result.gfx_config.display_mode.get_from_string(arg_parser.get_value('display-mode'))
	}

	return result
}
