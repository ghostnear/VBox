module mappers

interface GBMapper {
	name string
mut:
	set_rom_data(data []u8)
	read_byte(addr u16) u8
	write_byte(addr u16, value u8)
	read_word(addr u16) u16
	write_word(addr u16, value u16)
	get_pointer(addr u16) &u8
}
