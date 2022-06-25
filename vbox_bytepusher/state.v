// BytePusher VM state handling module
module vbox_bytepusher

import os { read_bytes }

/*	Struct Definition	*/
pub struct BytePusherState {
mut:
	mem	[]u8
	pc	u32
}

/*	Private Methods	*/

// Fetches 3-byte value at the specified adress
fn (mut v BytePusherState) fetch(pc u32) u32 {
	return u32(v.mem[pc]) << 16 | u32(v.mem[pc + 1]) << 8 | u32(v.mem[pc + 2])
}

/*	Public Methods	*/

// Initialises the state with the default values
pub fn (mut v BytePusherState) init() {
	v.pc = 0
	v.mem = []u8{len: 0x1000008, init: 0}
}

// Loads a ROM from the specified path
pub fn (mut v BytePusherState) load(path string) {
	by := read_bytes(path) or { panic("Input file not found.") }
	// File is too big
	if by.len > 0x1000000 {
		panic("File too big to be a BytePusher ROM.")
	}
	else {
		// Copy the bytes to the start of the VM array
		copy(mut v.mem, by)
	}
}

// Inner loop called by the VM
pub fn (mut v BytePusherState) inner_loop() {
	mut i := 65536
	v.pc = v.fetch(2)
	for i > 0 {
		v.mem[v.fetch(v.pc + 3)] = v.mem[v.fetch(v.pc)]
		v.pc = v.fetch(v.pc + 6)
		i--
	}
}