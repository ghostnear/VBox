module chip8

// The documentations that were mainly used for this:
// https://github.com/chip-8/extensions
// https://github.com/trapexit/chip-8_documentation
import app
import time

// Virtual machine config.
pub struct VMConfig {
pub mut:
	rom_path   string
	gfx_config DisplayConfig
	inp_config InputConfig
}

// CHIP8 virtual machine structure.
[heap]
pub struct VM {
mut:
	app              &app.App = unsafe { nil }
	cpu              CPU
	mem              Memory
	gfx              Display
	snd              Audio
	inp              Input
	tim              Timers
	rom              ROM
	emulation_speed  f64
	emulation_thread &thread = unsafe { nil }
}

// Creates a new instance of the VM.
[inline]
pub fn new_vm(cfg VMConfig, parent &app.App) &VM {
	// TODO: use configs and subsystems like for gfx
	mut v := &VM{
		app: parent
		emulation_speed: 300.0
		tim: new_tim()
		mem: new_mem()
	}

	// Initialise subsystems
	v.cpu = new_cpu(v)
	v.inp = new_inp(cfg.inp_config, mut v)
	v.gfx = new_dsp(cfg.gfx_config, v)

	// Normal res font
	v.mem.copy_bytes(0, [
		u8(0xF0),
		0x90,
		0x90,
		0x90,
		0xF0,
		// 0
		0x20,
		0x60,
		0x20,
		0x20,
		0x70,
		// 1
		0xF0,
		0x10,
		0xF0,
		0x80,
		0xF0,
		// 2
		0xF0,
		0x10,
		0xF0,
		0x10,
		0xF0,
		// 3
		0x90,
		0x90,
		0xF0,
		0x10,
		0x10,
		// 4
		0xF0,
		0x80,
		0xF0,
		0x10,
		0xF0,
		// 5
		0xF0,
		0x80,
		0xF0,
		0x90,
		0xF0,
		// 6
		0xF0,
		0x10,
		0x20,
		0x40,
		0x40,
		// 7
		0xF0,
		0x90,
		0xF0,
		0x90,
		0xF0,
		// 8
		0xF0,
		0x90,
		0xF0,
		0x10,
		0xF0,
		// 9
		0xF0,
		0x90,
		0xF0,
		0x90,
		0x90,
		// A
		0xE0,
		0x90,
		0xE0,
		0x90,
		0xE0,
		// B
		0xF0,
		0x80,
		0x80,
		0x80,
		0xF0,
		// C
		0xE0,
		0x90,
		0x90,
		0x90,
		0xE0,
		// D
		0xF0,
		0x80,
		0xF0,
		0x80,
		0xF0,
		// E
		0xF0,
		0x80,
		0xF0,
		0x80,
		0x80,
		// F
	])

	// High res font
	v.mem.copy_bytes(5 * 0x10, [
		u8(0xff),
		0xff,
		0xc3,
		0xc3,
		0xc3,
		0xc3,
		0xc3,
		0xc3,
		0xff,
		0xff,
		// 0
		0x0c,
		0x0c,
		0x3c,
		0x3c,
		0x0c,
		0x0c,
		0x0c,
		0x0c,
		0x3f,
		0x3f,
		// 1
		0xff,
		0xff,
		0x03,
		0x03,
		0xff,
		0xff,
		0xc0,
		0xc0,
		0xff,
		0xff,
		// 2
		0xff,
		0xff,
		0x03,
		0x03,
		0xff,
		0xff,
		0x03,
		0x03,
		0xff,
		0xff,
		// 3
		0xc3,
		0xc3,
		0xc3,
		0xc3,
		0xff,
		0xff,
		0x03,
		0x03,
		0x03,
		0x03,
		// 4
		0xff,
		0xff,
		0xc0,
		0xc0,
		0xff,
		0xff,
		0x03,
		0x03,
		0xff,
		0xff,
		// 5
		0xff,
		0xff,
		0xc0,
		0xc0,
		0xff,
		0xff,
		0xc3,
		0xc3,
		0xff,
		0xff,
		// 6
		0xff,
		0xff,
		0x03,
		0x03,
		0x0c,
		0x0c,
		0x30,
		0x30,
		0x30,
		0x30,
		// 7
		0xff,
		0xff,
		0xc3,
		0xc3,
		0xff,
		0xff,
		0xc3,
		0xc3,
		0xff,
		0xff,
		// 8
		0xff,
		0xff,
		0xc3,
		0xc3,
		0xff,
		0xff,
		0x03,
		0x03,
		0xff,
		0xff,
		// 9
	])

	// Load the ROM
	v.load_rom(cfg.rom_path)

	return v
}

// Starts the emulator on a new thread.
[inline]
pub fn (mut self VM) start() {
	// Only if we don't have a thread already active start and set the flag.
	// If used coretly, it's very likely that this is true.
	if _likely_(self.emulation_thread == unsafe { nil }) {
		self.emulation_thread = &(spawn self.internal_loop())
		self.cpu.execution_flag = true
		self.cpu.halt_flag = false
	}
}

// Waits for the execution thread to stop, then deletes it.
pub fn (mut self VM) wait_for_finish() bool {
	// Do nothing if we are still running the thread or if it doesnt exist.
	if self.cpu.execution_flag == true || self.emulation_thread == unsafe { nil } {
		// We are still waiting
		return true
	}

	// If thread is not already stopped, make sure to stop it.
	if self.emulation_thread != unsafe { nil } {
		self.emulation_thread.wait()
		self.emulation_thread = unsafe { nil }
	}

	return false
}

// Marks the emulation thread as stopped, doesn't do any actual thread stopping.
// Use stop_and_wait() for that instead.
[inline]
pub fn (mut self VM) stop() {
	self.cpu.execution_flag = false
}

// Reads a ROM file from the specified path.
[inline]
pub fn (mut self VM) load_rom(path string) {
	self.rom.load_from_file(path)
	self.mem.load_rom(self.rom)
}

// Steps the CPU once, useful for debugging
fn (mut self VM) step_once() {
	self.cpu.step(mut self)
}

// Steps the CPU for an arbitrary number of instructions, useful for the same debugging.
pub fn (mut self VM) step_multiple_times(times int) {
	for index := times; index > 0; index-- {
		self.step_once()
	}
}

// Internal loop that does the emulation on a different thread.
fn (mut self VM) internal_loop() {
	// Infinite loop
	for {
		// Start timing
		self.tim.emulation_timer.restart()

		// Compensate for the passed ammout of time.
		for _likely_(self.tim.emulation_dt > 1e+9 / self.emulation_speed && !self.cpu.halt_flag
			&& self.cpu.execution_flag) {
			self.step_once()
			self.tim.emulation_dt -= 1e+9 / self.emulation_speed
		}

		// Do drawing only if required
		if self.gfx.draw_flag {
			self.gfx.render()
			self.gfx.draw_flag = false
		}

		// Sleep till next instruction
		time.sleep(int(1e+9 / self.emulation_speed - self.tim.emulation_dt))

		// Update the timings and prepare for next step.
		self.tim.update()

		// Stop entirely when we are forced to
		if _unlikely_(!self.cpu.execution_flag) {
			break
		}
	}
}

pub fn (mut self VM) destroy() {
	// TODO: delete everything else
	self.inp.destroy()
}
