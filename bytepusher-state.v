module vbox_bytepusher_state

import os { read_bytes }

/*	Struct Definition	*/
pub struct BytePusherState {
mut:
	mem	[]byte
	pc	int
}

/*	Private Methods	*/

// Fetches 3-byte value at the specified adress
fn (mut v BytePusherState) fetch(pc int) int {
	return v.mem[pc] << 16 | v.mem[pc + 1] << 8 | v.mem[pc + 2]
}

/*	Public Methods	*/

// Initialises the state with the default values
pub fn (mut v BytePusherState) init() {
	v.pc = 0
	v.mem = []byte{len: 0x1000008, init: 0}
}

// Loads a ROM from the specified path
pub fn (mut v BytePusherState) load(path string) {
	//by := read_bytes(path) or { panic("Input file not found.") }
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