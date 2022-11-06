module chip8

// CHIP8 memory structure.
struct Memory
{
mut:
	ram []u8
}

// Fetches a 16-bit word from the memory at the specified address.
pub fn (self Memory) fetch_word(address u16) u16
{
	return 0x0000
}