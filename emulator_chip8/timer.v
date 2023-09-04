module emulator_chip8

struct Timer {
	rate f64 = 1.0 / 60
mut:
	timer f64
	value u8
}

pub fn (mut self Timer) set_value(value u8) {
	self.value = value
}

pub fn (mut self Timer) get_value() u8 {
	return self.value
}

pub fn (mut self Timer) update(delta f64) {
	self.timer += delta
	for self.timer > self.rate  {
		self.timer -= self.rate
		if self.value > 0 {
			self.value--
		}
	}
}
