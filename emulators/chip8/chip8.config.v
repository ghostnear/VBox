module chip8

import core

// Virtual machine config.
pub struct VMConfig {
pub mut:
	rom_path   string
	gfx_config DisplayConfig
	inp_config InputConfig
}

pub fn fetch_vm_config(arg_parser &core.ArgParser) VMConfig
{
	mut result := chip8.VMConfig{}
	
	// Check for variations in the arguments.
	if arg_parser.is_set('rom') {
		result.rom_path = arg_parser.get_value('rom')
	}

	return result
}