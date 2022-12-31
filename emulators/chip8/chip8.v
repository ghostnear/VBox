module chip8

// The documentations that were mainly used for this:
// https://github.com/chip-8/extensions
// https://github.com/trapexit/chip-8_documentation
import sdl
import time
import term
import core as app

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
	emulation_speed  f64     = 300.0
	emulation_thread &thread = unsafe { nil }
}

// Creates a new instance of the VM.
[inline]
pub fn new_vm(cfg VMConfig, mut parent app.App) &VM {
	// Create the VM.
	mut v := &VM{
		app: parent
	}

	// Initialise subsystems
	v.tim = new_tim()
	v.cpu = new_cpu(v)
	v.mem = new_mem(v)
	v.inp = new_inp(cfg.inp_config, mut v)
	v.gfx = new_dsp(cfg.gfx_config, v)

	// Copy the normal and high res fonts in memory here.
	v.mem.copy_bytes(0, font_lowres)
	v.mem.copy_bytes(5 * 0x10, font_highres)

	// Load the ROM
	v.load_rom(cfg.rom_path)

	// Add hooks for the VM drawing.
	// TODO: move the drawing in display.v
	parent.hooks.add_hook('draw', 'chip8', v.draw)

	return v
}

// Starts the emulator on a new thread.
[inline]
pub fn (mut self VM) start() {
	// Only if we don't have a thread already active start and set the flag.
	if _likely_(self.emulation_thread == unsafe { nil }) { // If used coretly, it's very likely that this is true.
		self.emulation_thread = &(spawn self.internal_loop())
		self.cpu.execution_flag = true
		self.cpu.halt_flag = false
	}
}

// Draws to the screen. TODO: move this in display.v
pub fn (mut self VM) draw(args voidptr) {
	// Do rendering if required.
	if self.gfx.draw_flag {
		self.gfx.render()
		self.gfx.draw_flag = false
	}

	match self.app.gfx.display_mode {
		// Print all in terminal.
		.terminal {
			for y := 0; y < self.gfx.size.y; y++ {
				mut line := ''
				for x := 0; x < self.gfx.size.x; x++ {
					if self.gfx.get_pixel(x, y) == 1 {
						line += term.rgb(0xAA, 0xAA, 0xAA, '█')
					} else {
						line += term.bg_rgb(0x11, 0x11, 0x11, ' ')
					}
				}
				println(line)
			}
		}
		// Draw the SDL texture to the screen
		.sdl {
			sdl.render_copy(self.app.gfx.sdl_renderer, self.gfx.sdl_display, sdl.null,
				sdl.null)
		}
		// This shouldn't happen.
		else {}
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

/*
*	Marks the emulation thread as stopped, doesn't do any actual thread stopping.
 *	Use stop_and_wait() for that instead.
*/
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

// Steps the CPU once, useful for debugging.
[inline]
fn (mut self VM) step_once() {
	self.cpu.step(mut self)
}

// Steps the CPU for an arbitrary number of instructions, useful for debugging as well.
[inline]
pub fn (mut self VM) step_multiple_times(times int) {
	for index := times; index > 0; index-- {
		self.step_once()
	}
}

// Internal loop that handles the emulation on the second thread.
fn (mut self VM) internal_loop() {
	for {
		// Start timing.
		self.tim.emulation_timer.restart()

		// Compensate for the passed time.
		passed_time := 1e+9 / self.emulation_speed
		for _likely_(self.tim.emulation_dt > passed_time && !self.cpu.halt_flag
			&& self.cpu.execution_flag) {
			self.step_once()
			self.tim.emulation_dt -= passed_time
		}

		// Sleep till next instruction
		time.sleep(int(passed_time - self.tim.emulation_dt))

		// Update the timings and prepare for next step.
		self.tim.update()

		// Stop entirely when we are forced to.
		if _unlikely_(!self.cpu.execution_flag) { // Most of the time this should be false.
			break
		}
	}
}

pub fn (mut self VM) destroy() {
	// TODO: delete everything else
	self.inp.destroy()
}
