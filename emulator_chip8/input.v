module emulator_chip8

import sdl

struct Input {
	keybinds []sdl.KeyCode = [
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
	// Note: god bless the V formatter for not putting a tab here...
]
mut:
	keys [0x10]u8
}

pub fn (mut self Input) set_key(key sdl.Keycode, value u8) {
	for index, key_value in self.keybinds {
		if key_value == unsafe { sdl.KeyCode(key) } {
			self.keys[index] = value
			return
		}
	}
}

pub fn (mut self Input) get_first_key_pressed() u8 {
	for index, key_value in self.keys {
		if key_value != 0 {
			return u8(index)
		}
	}
	return 0xFF
}

pub fn (mut self Input) get_key(key u8) u8 {
	return self.keys[key]
}
