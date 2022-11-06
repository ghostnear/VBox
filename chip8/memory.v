module chip8

// CHIP8 memory structure.
struct Memory
{
mut:
	ram []u8
}

// Fetches a byte form the memory at the specified address.
[direct_array_access]
pub fn (self Memory) fetch_byte(address u16) u8
{
	return self.ram[address]
}

// Copies an array of bytes directly to the memory at the specified offset.
[direct_array_access]
pub fn (mut self Memory) copy_bytes(offset u16, bytes []u8)
{
	for index := 0; index < bytes.len; index++
	{
		self.ram[offset + index] = bytes[index]
	}
}

// Loads a ROM to the memory at the specified offset.
pub fn (mut self Memory) load_rom(rom ROM)
{
	println("Loaded ROM with length ${ rom.data.len } bytes!")
	self.copy_bytes(0x200, rom.data)
}

// Fetches a 16-bit word from the memory at the specified address.
pub fn (self Memory) fetch_word(address u16) u16
{
	return (u16(self.fetch_byte(address)) << 8) | self.fetch_byte(address + 1)
}

// Creates a new memory instance
fn new_mem() &Memory
{
	mut mem := &Memory {
		ram: []u8 {len: 0x10000, cap: 0x10000, init: 0}
	}
	return mem
}