module chip8

import term
import utilities as utils

struct Display
{
pub mut:
	draw_flag bool
	size utils.Vec2<int>
	buffer []u8
}

[inline]
pub fn (mut self Display) get_pixel(position utils.Vec2<int>) u8
{
	array_index := position.x / 8 + self.size.x * position.y / 8
	return (self.buffer[array_index] >> (position.x % 8)) & 1
}

[inline]
pub fn (mut self Display) set_pixel(position utils.Vec2<int>)
{
	array_index := position.x / 8 + self.size.x * position.y / 8
	self.buffer[array_index] |= 1 << (position.x % 8)
}

[inline]
pub fn (mut self Display) xor_pixel(position utils.Vec2<int>) bool
{
	array_index := position.x / 8 + self.size.x * position.y / 8
	mut result := false
	if self.get_pixel(position) == 1 && (self.buffer[array_index] & 1 << (position.x % 8)) == 1
	{
		result = true
	}
	self.buffer[array_index] ^= 1 << (position.x % 8)
	return result
}

pub fn (mut self Display) render_to_terminal()
{
	term.clear()
	mut position := utils.Vec2<int>
	{
		x: 0
		y: 0
	}
	for ; position.y < self.size.y; position.y++
	{
		for ; position.x < self.size.x; position.x++
		{
			if self.get_pixel(position) == 1
			{
				print("#")
			}
			else
			{
				print(" ")
			}
		}
		println("")
	}
}

pub fn (mut self Display) resize(newSize utils.Vec2<int>)
{
	self.size = newSize
	self.buffer = []u8{len: self.size.x * self.size.y / 8, cap: self.size.x * self.size.y / 8, init: 0}
}

pub fn (mut self Display) clear()
{
	self.draw_flag = true
	for index := 0; index < self.buffer.len; index++
	{
		self.buffer[index] = 0
	}
}

[inline]
pub fn new_dsp() &Display
{
	mut display := &Display{
		draw_flag: true
	}
	display.resize(
		utils.Vec2<int>{
			x: 64
			y: 32
		}
	)
	return display
}