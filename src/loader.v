module main

import os
import json
import emulator_common as common
import emulator_chip8 as chip8
import emulator_gameboy as gameboy

struct LoaderConfigDummy {
	emu_type string
}

pub fn load_emulator(path string) &common.Emulator {
	contents := os.read_file(path) or {
		panic('Could not read contents from file at path ${path}!')
	}

	result_config := json.decode(LoaderConfigDummy, contents) or {
		panic('Could not find field type in config at path ${path}!')
	}

	// TODO: research if this is somehow simplifiable
	match result_config.emu_type {
		'chip8' {
			emulator_config := json.decode(chip8.Config, contents) or {
				panic('Could not parse CHIP8 JSON config at path ${path}!')
			}

			return chip8.create_emulator(emulator_config)
		}
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
