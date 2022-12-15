module chip8

[heap]
struct Input
{
pub mut:
	keys []u8

	// TODO: key bindings and hooks in the main app.
}

[inline]
pub fn (self Input) is_pressed(keyIndex u8) bool
{
	return self.keys[keyIndex / 8] & (1 << (keyIndex % 8)) != 0
}

[inline]
pub fn new_inp() &Input
{
	input := &Input{
		keys: []u8{len: 0x2, cap: 0x2, init: 0}
	}
	return input
}