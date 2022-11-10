module chip8

import os

// ROM data structure.
pub struct ROM
{
pub mut:
	data []u8
}

pub fn (mut self ROM) load_from_file(path string)
{
	// Check if file exists and can be opened.
	mut rom_file := os.open(path) or {
		println("Couldn't open file at path ${ path }!")
		return
	}

	// Check the file size, it is unlikely that the file is too big, but just to be safe.
	rom_size := os.file_size(path)
	if _unlikely_(rom_size >= 0x10000)
	{
		rom_file.close()
		println("ROM file at path ${ path } is too big to be a CHIP8 ROM!")
		return
	}

	// Finally read and close
	self.data = rom_file.read_bytes(int(rom_size))
	rom_file.close()
}