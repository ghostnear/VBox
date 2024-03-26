module vchip8

pub struct Emulator {
}

pub fn (mut self Emulator) configure(config map[string]string) !bool {
	return true
}

fn (mut self Emulator) step() bool {
	return true
}

pub fn (mut self Emulator) update(delta f32) bool {
	if !self.step() {
		return false
	}

	return true
}

pub fn (mut self Emulator) draw() {
}
