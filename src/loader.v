module main

import os
import json
import utils
import emulator_chip8 as chip8
import emulator_gameboy as gameboy

struct LoaderConfigDummy {
	emu_type string
}

pub fn load_emulator(path string) &utils.Emulator {
	// Read JSON from config.
	contents := os.read_file(path) or {
		println('ERROR: Could not read contents from file at path ${path}!')
		exit(-1)
	}

	// This is so we get only the type and nothing else from the config first.
	result_config := json.decode(LoaderConfigDummy, contents) or {
		println('ERROR: Could not find field type in config at path ${path}!')
		exit(-1)
	}

	// TODO: research if this is somehow simplifiable
	// Setup emulator.
	match result_config.emu_type {
		'chip8' {
			emulator_config := json.decode(chip8.Config, contents) or {
				println('ERROR: Could not parse CHIP8 JSON config at path ${path}!')
				exit(-1)
			}

			return chip8.create_emulator(emulator_config)
		}
		'gameboy' {
			emulator_config := json.decode(gameboy.Config, contents) or {
				println('ERROR: Could not parse Gameboy JSON config at path ${path}!')
				exit(-1)
			}

			return gameboy.create_emulator(emulator_config)
		}
		else {
			println('ERROR: Unknown emulator type in config at path ${path}!')
			exit(-1)
		}
	}
}
