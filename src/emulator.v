module main

import vuxn
import vchip8

struct EmulatorConfig {
	preset string
	data   map[string]string
}

interface Emulator {
mut:
	// This is called to configure the virtual machine from an initial JSON config.
	configure(config map[string]string) !bool
	// This function is called to update the state of the virtual machine.
	update(delta f32) bool
	// This function should draw the current output to a framebuffer.
	draw()
}

fn create_emulator(config &EmulatorConfig) !Emulator {
	match config.preset {
		'uxn' {
			return vuxn.Emulator{}
		}
		'chip8' {
			return vchip8.Emulator{}
		}
		else {
			// TODO: throw error.
		}
	}
	return error('Invalid emulator specified in config: ${config.preset}')
}
