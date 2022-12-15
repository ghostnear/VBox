module app

import os
import log
import sdl
import term
import time
import locale
import v.util.version
import utilities as utils

pub const app_version_minor = '1'

pub const app_version_middle = '0'

pub const app_version_major = '0'

pub const app_version = '${app_version_major}.${app_version_middle}.${app_version_minor}'

// Struct that helps create the app.
pub struct AppConfig {
pub mut:
	gfx_config GraphicsConfig = GraphicsConfig{
		window_title: 'VBox ' + app.app_version
		display_mode: .other
	}
}

// Main struct that holds all app data.
[heap]
pub struct App {
pub mut:
	running bool = true
	log     log.Log
	gfx     Graphics
	input   Input
	locale  string = 'en'
}

[inline]
pub fn new_app(cfg AppConfig) &App {
	// Create app data.
	mut a := &App{
		log: log.Log{
			output_target: .file
			level: .debug
		}
	}

	// Create logging requirements.
	os.mkdir('logs') or {}

	// Check if there are 5 logs already, if so, delete the first one chronologically.
	mut files := os.ls('./logs/') or { [''] } // This should already exist, so no errors.
	for files.len >= 5 {
		os.rm('./logs/' + files[0]) or {} // Should work most of the times, unless the file is read only (shouldn't be the case).
		files = files[1..files.len]
	}
	a.log.set_full_logpath('./logs/' + time.now().str().replace(' ', '_').replace(':', '-') + '.log')

	// Log app data
	a.log.info(locale.get_string(a.locale, 'info_log_session_info'))
	a.log.info(locale.get_string(a.locale, 'info_log_app_version') + app.app_version)
	a.log.info(locale.get_string(a.locale, 'info_log_language_name') + a.locale + ' (' +
		locale.get_string(a.locale, 'language_name') + ')')
	a.log.info(locale.get_string(a.locale, 'info_log_compiled_with') + version.full_v_version(true))
	a.log.info('-------------------------------')

	// Stuff that can generate errors goes here.
	a.gfx = new_gfx(cfg.gfx_config, a) or {
		term.clear()
		utils.print_fatal_error(a.locale, err.str())
		a.log.error(err.str())
		exit(-1)
	}

	// Init complete.
	a.log.info(locale.get_string(a.locale, 'info_log_init_properly'))
	a.log.flush()

	// Execute this when app quits.
	C.atexit(a.destroy)

	return a
}

[inline]
pub fn (self App) is_running() bool {
	return self.running
}

[inline]
pub fn (mut self App) quit() {
	// Stop app and save logs
	self.running = false
	self.log.info(locale.get_string(self.locale, 'info_log_quitting'))
	self.log.flush()
}

[inline]
pub fn (mut self App) destroy() {
	// Destroy all graphics related data.
	self.gfx.destroy() or {
		self.log.error(err.str())
		utils.print_fatal_error(self.locale, err.str())
		exit(-1)
	}

	// Quit SDL
	sdl.quit()

	// Log that exit has been done and make sure everything is flushed properly.
	self.log.info(locale.get_string(self.locale, 'info_log_exit_properly'))
	self.log.flush()
}
