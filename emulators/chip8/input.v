module chip8

import sdl

struct InputConfig {
pub mut:
	keybind []sdl.KeyCode = [
	sdl.KeyCode.x,
	sdl.KeyCode._1,
	sdl.KeyCode._2,
	sdl.KeyCode._3,
	sdl.KeyCode.q,
	sdl.KeyCode.w,
	sdl.KeyCode.e,
	sdl.KeyCode.a,
	sdl.KeyCode.s,
	sdl.KeyCode.d,
	sdl.KeyCode.z,
	sdl.KeyCode.c,
	sdl.KeyCode._4,
	sdl.KeyCode.r,
	sdl.KeyCode.f,
	sdl.KeyCode.v,
]
}

[heap]
struct Input {
pub mut:
	parent  &VM = unsafe { nil }
	keys    []u8
	keybind []sdl.KeyCode
}

pub fn (mut self Input) on_key_down(key voidptr) {
	keycode := *(&sdl.KeyCode(key))
	// TODO: figure out why this doesnt work right?
	mut index := 0
	for keyvalue in self.keybind {
		if keycode == keyvalue {
			self.keys[index / 8] |= 1 << (index % 8)
		}
		index++
	}
}

pub fn (mut self Input) on_key_up(key voidptr) {
	keycode := *(&sdl.KeyCode(key))
	// TODO: figure out why this doesnt work right?
	mut index := 0
	for keyvalue in self.keybind {
		if keycode == keyvalue {
			self.keys[index / 8] &= ~(1 << (index % 8))
		}
		index++
	}
}

pub fn (mut self Input) destroy() {
	// Remove hooks on app destroy.
	self.parent.app.inp.hooks.remove_hook('key_up', 'chip8_key_up')
	self.parent.app.inp.hooks.remove_hook('key_up', 'chip8_key_down')
}

// Checks if a key has been pressed.
[inline]
pub fn (self Input) is_pressed(keyIndex u8) bool {
	return self.keys[keyIndex / 8] & (1 << (keyIndex % 8)) != 0
}

// Create a new CHIP8 input manager.
[inline]
pub fn new_inp(cfg InputConfig, mut parent VM) &Input {
	input := &Input{
		parent: parent
		keybind: cfg.keybind
		keys: []u8{len: 0x2, cap: 0x2, init: 0}
	}

	// Set up hooks in main input
	parent.app.inp.hooks.add_hook('key_up', 'chip8_key_up', input.on_key_up)
	parent.app.inp.hooks.add_hook('key_down', 'chip8_key_down', input.on_key_down)

	return input
}
