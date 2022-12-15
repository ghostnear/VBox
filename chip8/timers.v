module chip8

import time

[heap]
struct Timers
{
pub mut:
	// All timers are decreasing at a rate of 60hz.
	dt u8
	st u8
	hardware_timer time.StopWatch
	hardware_dt f64

	// Used for calculating the steps required to emulate.
	emulation_timer time.StopWatch
	emulation_dt f64
}

[inline]
pub fn (mut self Timers) update()
{
	self.emulation_dt += self.emulation_timer.elapsed().nanoseconds()
	self.hardware_dt += self.hardware_timer.elapsed().nanoseconds()

	// Update the timer registers.
	// ENHANCEME: use divisions somehow?
	for self.hardware_dt > 1.e9 / 60.0
	{
		if self.dt > 0
		{
			self.dt -= 1
		}
		if self.st > 0
		{
			self.st -= 1
		}
		self.hardware_dt -= 1.e9 / 60.0
	}
}

// Creates a new timer instance.
[inline]
fn new_tim() &Timers
{
	mut tim := &Timers {
		dt: 0
		st: 0
		hardware_timer: time.new_stopwatch()
		hardware_dt: 0
		emulation_timer: time.new_stopwatch()
		emulation_dt: 0
	}
	return tim
}