module chip8

import time

// The hardware timers are decreased at a rate of 60hz.
const freq_60hz = 1.e9 / 60.0

[heap]
struct Timers {
pub mut:
	// The actual registers.
	dt u8
	st u8
mut:
	// Used for calculating the register decreasing time.	
	hardware_timer time.StopWatch
	hardware_dt    f64
	// Used for calculating the steps required to emulate.
	emulation_timer time.StopWatch
	emulation_dt    f64
	// NOTE: all struct fields are 0-ed by default.
}

[inline]
pub fn (mut self Timers) update() {
	self.emulation_dt += self.emulation_timer.elapsed().nanoseconds()
	self.hardware_dt += self.hardware_timer.elapsed().nanoseconds()

	// Update the timer registers.
	for self.hardware_dt > chip8.freq_60hz {
		if self.dt > 0 {
			self.dt--
		}
		if self.st > 0 {
			self.st--
		}
		self.hardware_dt -= chip8.freq_60hz // The autoformatter really requires the chip8 prefix for some reason.
	}
}

// Creates a new timer instance.
[inline]
fn new_tim() &Timers {
	mut tim := &Timers{
		hardware_timer: time.new_stopwatch()
		emulation_timer: time.new_stopwatch()
	}
	return tim
}
