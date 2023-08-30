module mappers

// This file contains the interface for all the Gameboy mappers.

interface Mapper {
	name string
mut:
	load_rom_bytes(data []u8)
	read_byte(addr u16) u8
	write_byte(addr u16, value u8)
	read_word(addr u16) u16
	write_word(addr u16, value u16)
	get_pointer(addr u16) &u8
}
