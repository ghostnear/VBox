module main

import os
import log
import json

fn main() {
	path := './defaults/uxn-config.json'

	// Custom logger
	mut logger := log.new_thread_safe_log()
	os.rm('./last.log') or {}
	logger.set_full_logpath('./last.log')
	logger.set_level(log.Level.debug)
	log.set_logger(logger)

	mut config := json.decode(EmulatorConfig, os.read_file(path) or { '' }) or {
		// TODO: display error.
		log.error('Could not parse config JSON: ${err}')
		return
	}

	mut emulator := create_emulator(config) or {
		// TODO: display error.
		log.error('Could not create the emulator: ${err}')
		return
	}

	emulator.configure(config.data) or {
		// TODO: display error.
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
