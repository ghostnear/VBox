module main

import os
import log
import json
import sdl

fn show_error(title string, message string) {
	sdl.show_simple_message_box(u32(sdl.MessageBoxFlags.error), title.str, message.str,  unsafe { nil })
}

fn main() {
	path := './defaults/chip8-config.json'

	// Custom logger
	mut logger := log.new_thread_safe_log()
	os.rm('./last.log') or {}
	logger.set_full_logpath('./last.log')
	logger.set_level(log.Level.debug)
	log.set_logger(logger)

	mut config := json.decode(EmulatorConfig, os.read_file(path) or { '' }) or {
		show_error( 'Error', 'Could not parse config JSON:\n${err}')
		log.error('Could not parse config JSON: ${err}')
		return
	}

	mut emulator := create_emulator(config) or {
		show_error( 'Error', 'Could not create the emulator:\n${err}')
		log.error('Could not create the emulator: ${err}')
		return
	}

	emulator.configure(config.data) or {
		show_error( 'Error', 'Could not configure the emulator:\n${err}')
		log.error('Could not configure the emulator: ${err}')
		return
	}

	for {
		if !emulator.update(0) {
			log.info('Emulator quit running.')
			return
		}

		emulator.draw()
	}
}
