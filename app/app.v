module app

import os
import log
import term
import time
import locale
import v.util.version

const app_version_minor = "1"
const app_version_middle = "0"
const app_version_major = "0"
const app_version = "${app_version_major}.${app_version_middle}.${app_version_minor}"

// Struct that helps create the app.
pub struct AppConfig
{
pub mut:
	gfx_config GraphicsConfig = GraphicsConfig {
		window_title: "VBox" + app_version
		display_mode: .other
	}
}

// Main struct that holds all app data.
[heap]
struct App
{
mut:
	log 		log.Log
	gfx			Graphics
	locale		string = "en"
}

[inline]
pub fn new_app(cfg AppConfig) &App
{
	// Create app data.
	mut a := &App {
		log: log.Log {
			output_target: .file
			level: .debug
		}
	}

	// Create logging requirements.
	os.mkdir('logs') or {}
	a.log.set_full_logpath("./logs/" + time.now().str().replace(' ', '_').replace(':', '-') + ".log")

	// Log app data
	a.log.info(locale.get_string(a.locale, "info_log_session_info"))
	a.log.info(locale.get_string(a.locale, "info_log_app_version") + app_version)
	a.log.info(locale.get_string(a.locale, "info_log_language_name") + a.locale + " (" + locale.get_string(a.locale, "language_name") + ")")
	a.log.info(locale.get_string(a.locale, "info_log_compiled_with") + version.full_v_version(true))
	a.log.info("-------------------------------")

	// Stuff that can generate errors goes here.
	a.gfx = new_gfx(cfg.gfx_config, a) or {
		term.clear()
		locale.print_fatal_error(a.locale, err.str())
		a.log.error(err.str())
		exit(-1)
	}

	// Init complete.
	a.log.info(locale.get_string(a.locale, "info_log_init_properly"))

	return a
}

[inline]
pub fn(mut self App) quit()
{
	// Destroy all graphics related data.
	self.gfx.destroy() or {
		self.log.error(err.str())
		exit(-1)
	}

	// Log that exit has been done.
	self.log.info(locale.get_string(self.locale, "info_log_exit_properly"))
}

[inline]
pub fn(self &App) start()
{
	
	// Create new CHIP8 VM and force load the test rom for now.
	// TODO: not do this...
	/*term.clear()
	mut test_vm := chip8.new_vm()
	test_vm.load_rom('roms/chip8/games/Tetris [Fran Dachille, 1991].ch8')

	// Start the emulation thread and wait for it to finish.
	test_vm.start()
	for
	{
		if !test_vm.wait_for_finish()
		{
			break
		}

		// Update 60 times a second just to be sure.
		// TODO: this thing should have an actual update time, depending on the UI type.
		time.sleep(1e+9 / 60.0)
	}*/
}