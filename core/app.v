module core

import os
import log
import sdl
import term
import time
import locale
import v.util.version
import utilities as utils

const error_exit_code = -1

// Main struct that holds all app data.
[heap]
pub struct App {
pub mut:
	running bool = true
	log     log.Log
	gfx     Graphics
	inp     Input
	locale  string = 'en'
	hooks   utils.HookManager
}

// Stops the current thread till next frame needs to be computed.
pub fn (self App) wait_for_next_frame() {
	// TODO: this thing should have an actual update time, depending on the UI type. Or configurable.
	time.sleep(1e+9 / 30.0)
}

[inline]
pub fn new_app(cfg AppConfig) &App {
	mut a := &App{
		log: log.Log{
			output_target: .file
			level: .debug
		}
	}

	// Execute this when app quits.
	C.atexit(a.destroy)

	// TODO: logs should not have hardcoded paths.

	// Create the log folder as it needs to exist before we can do anything.
	os.mkdir('logs') or {}

	// Check if there are 5 logs already, if so, delete the first one chronologically.
	mut files := os.ls('./logs/') or { [''] }
	for files.len >= 5 {
		os.rm('./logs/' + files[0]) or {}
		files = files[1..files.len]
	}

	/*
	*	Start logging app data.
	 *	This is the log header.
	*/
	a.log.set_full_logpath('./logs/' + time.now().str().replace(' ', '_').replace(':', '-') + '.log')
	a.log.info(locale.get_string(a.locale, 'info_log_session_info'))
	a.log.info(locale.get_format_string(a.locale, 'info_log_app_version', app_version))
	lang_name := locale.get_string(a.locale, 'language_name')
	a.log.info(locale.get_format_string(a.locale, 'info_log_language_name', a.locale,
		lang_name))
	v_version := version.full_v_version(true)
	a.log.info(locale.get_format_string(a.locale, 'info_log_compiled_with', v_version))
	a.log.info('-------------------------------')

	// Start intiializing everything properly.
	a.gfx = new_gfx(cfg.gfx_config, a) or {
		term.clear()
		utils.print_fatal_error(a.locale, err.str())
		a.log.error(err.str())
		exit(core.error_exit_code)
	}
	a.inp = new_input(a)
	a.log.info(locale.get_string(a.locale, 'info_log_init_properly'))
	a.log.flush()

	return a
}

// Returns true if the app is still running.
[inline]
pub fn (self App) is_running() bool {
	return self.running
}

// Main draw method of the app to be used in the main loop.
pub fn (mut self App) draw() {
	self.hooks.call_all_hooks('draw', sdl.null)

	match self.gfx.display_mode {
		// Reset the cursor position to top left and make sure cursor is hidden.
		.terminal {
			term.hide_cursor()
			term.set_cursor_position(x: 0, y: 0)
		}
		// Update the display
		.sdl {
			sdl.render_present(self.gfx.sdl_renderer)
		}
		// This shouldn't happen.
		else {}
	}
}

// Called to exit the main loop.
[inline]
pub fn (mut self App) quit() {
	self.running = false
	self.log.info(locale.get_string(self.locale, 'info_log_quitting'))
	self.log.flush()
}

// Free everything the app has allocated.
[inline]
pub fn (mut self App) destroy() {
	// Destroy all graphics related data.
	self.gfx.destroy() or {
		self.log.error(err.str())
		utils.print_fatal_error(self.locale, err.str())
		exit(core.error_exit_code)
	}
	sdl.quit()

	// Log that exit has been done and make sure everything is flushed properly.
	self.log.info(locale.get_string(self.locale, 'info_log_exit_properly'))
	self.log.flush()
}
