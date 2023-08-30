module main

import os
import json
import utils
import emulator_gameboy as gameboy

struct LoaderConfigDummy {
	emu_type string
}

pub fn load_emulator(path string) &utils.Emulator {
	// Read JSON from config.
	contents := os.read_file(path) or {
		panic('Could not read contents from file at path ${path}!')
	}

	// This is so we get only the type and nothing else from the config first.
	result_config := json.decode(LoaderConfigDummy, contents) or {
		panic('Could not find field type in config at path ${path}!')
	}

	// TODO: research if this is somehow simplifiable
	// Setup emulator.
	match result_config.emu_type {
		'gameboy' {
			emulator_config := json.decode(gameboy.Config, contents) or {
				panic('Could not parse Gameboy JSON config at path ${path}!')
			}

			return gameboy.create_emulator(emulator_config)
		}
		else {
			panic('Unknown emulator type in config at path ${path}!')
		}
	}
}
