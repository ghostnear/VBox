module chip8

import sdl

struct InputConfig
{
pub mut:
	keybind	[]sdl.KeyCode = [
		sdl.KeyCode.x, sdl.KeyCode._1, sdl.KeyCode._2, sdl.KeyCode._3,
		sdl.KeyCode.q, sdl.KeyCode.w, sdl.KeyCode.e,
		sdl.KeyCode.a, sdl.KeyCode.s, sdl.KeyCode.d,
		sdl.KeyCode.z, sdl.KeyCode.c, sdl.KeyCode._4,
		sdl.KeyCode.r, sdl.KeyCode.f, sdl.KeyCode.v
	]
}

[heap]
struct Input
{
pub mut:
	parent 		&VM = unsafe{ nil }
	keys 		[]u8
	keybind		[]sdl.KeyCode
}

pub fn (mut self Input) on_key_down(key voidptr)
{
	keycode := *(&sdl.KeyCode(key))
	for index, keyvalue in self.keybind
	{
		if keycode == keyvalue
		{
			self.keys[index / 8] |= 1 << (index % 8)
		}	
	}
}

pub fn (mut self Input) on_key_up(key voidptr)
{
	keycode := *(&sdl.KeyCode(key))
	for index, keyvalue in self.keybind
	{
		if keycode == keyvalue
		{
			self.keys[index / 8] &= ~(1 << (index % 8))
		}	
	}
}

pub fn (mut self Input) destroy()
{
	self.parent.app.input.remove_hook("key_up", "chip8_key_up")
	self.parent.app.input.remove_hook("key_up", "chip8_key_down")
}

[inline]
pub fn (self Input) is_pressed(keyIndex u8) bool
{
	return self.keys[keyIndex / 8] & (1 << (keyIndex % 8)) != 0
}

[inline]
pub fn new_inp(cfg InputConfig, mut parent &VM) &Input
{
	input := &Input{
		parent: parent
		keybind: cfg.keybind
		keys: []u8{len: 0x2, cap: 0x2, init: 0}
	}

	// Set up hooks in main input
	parent.app.input.add_hook("key_up", "chip8_key_up", input.on_key_up)
	parent.app.input.add_hook("key_down", "chip8_key_down", input.on_key_down)

	return input
}