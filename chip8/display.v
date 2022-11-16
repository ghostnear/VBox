module chip8

import term
import utilities as utils

[heap]
struct Display
{
pub mut:
	draw_flag bool
	size utils.Vec2<int>
	buffer []u8
}

[inline]
pub fn (mut self Display) get_pixel(x int, y int) u8
{
	array_index := x / 8 + self.size.x * y / 8
	return (self.buffer[array_index] >> (x % 8)) & 1
}

[inline]
pub fn (mut self Display) set_pixel(x int, y int)
{
	array_index := x / 8 + self.size.x * y / 8
	self.buffer[array_index] |= 1 << (x % 8)
}

[inline]
pub fn (mut self Display) xor_pixel(x int, y int) int
{
	array_index := x / 8 + self.size.x * y / 8
	mut result := 0
	if self.get_pixel(x, y) == 1 && (self.buffer[array_index] & 1 << (x % 8)) == 1
	{
		result = 1
	}
	self.buffer[array_index] ^= 1 << (x % 8)
	return result
}

pub fn (mut self Display) render_to_terminal()
{
	term.clear()
	term.hide_cursor()
	for y := 0; y < self.size.y; y++
	{
		for x := 0; x < self.size.x; x++
		{
			if self.get_pixel(x, y) == 1
			{
				print("#")
			}
			else
			{
				print(" ")
			}
		}
		print("\n")
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