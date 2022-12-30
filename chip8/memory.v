module chip8

// CHIP8 memory structure.
[heap]
struct Memory {
mut:
	parent &VM = unsafe { nil }
	ram    []u8
}

// Fetches a byte from the memory at the specified address.
[direct_array_access; inline]
pub fn (self Memory) fetch_byte(address u16) u8 {
	return self.ram[address]
}

// Saves a byte to the memory at the specified address.
[direct_array_access; inline]
pub fn (mut self Memory) save_byte(address u16, value u8) {
	self.ram[address] = value
}

// Copies an array of bytes directly to the memory at the specified offset.
pub fn (mut self Memory) copy_bytes(offset u16, bytes []u8) {
	for index := 0; index < bytes.len; index++ {
		self.save_byte(offset + index, bytes[index])
	}
}

// Loads a ROM to the memory at the specified offset.
pub fn (mut self Memory) load_rom(rom ROM) {
	if rom.data.len > 0 {
		self.parent.app.log.info('Executable loaded successfully!')
		rom.log(mut self.parent.app.log)
		self.copy_bytes(0x200, rom.data)
	}
}

// Fetches a 16-bit word from the memory at the specified address.
[inline]
pub fn (self Memory) fetch_word(address u16) u16 {
	return (u16(self.fetch_byte(address)) << 8) | self.fetch_byte(address + 1)
}

// Creates a new memory instance from the specified config.
[inline]
fn new_mem(parent &VM) &Memory {
	mut mem := &Memory{
		parent: parent
		ram: []u8{len: 0x10000, cap: 0x10000, init: 0}
	}
	return mem
}
