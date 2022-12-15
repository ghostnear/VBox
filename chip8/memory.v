module chip8

// CHIP8 memory structure.
[heap]
struct Memory
{
mut:
	ram []u8
}

// Fetches a byte from the memory at the specified address.
[inline]
[direct_array_access]
pub fn (self Memory) fetch_byte(address u16) u8
{
	return self.ram[address]
}

// Saves a byte to the memory at the specified address.
[inline]
[direct_array_access]
pub fn (mut self Memory) save_byte(address u16, value u8)
{
	self.ram[address] = value
}

// Copies an array of bytes directly to the memory at the specified offset.
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
	if rom.data.len > 0
	{
		println("Loaded ROM with length ${ rom.data.len } bytes!")
		// TODO: use the logs for this.
		self.copy_bytes(0x200, rom.data)
	}
}

// Fetches a 16-bit word from the memory at the specified address.
[inline]
pub fn (self Memory) fetch_word(address u16) u16
{
	return (u16(self.fetch_byte(address)) << 8) | self.fetch_byte(address + 1)
}

// Creates a new memory instance
[inline]
fn new_mem() &Memory
{
	mut mem := &Memory {
		ram: []u8 {len: 0x10000, cap: 0x10000, init: 0}
	}
	return mem
}