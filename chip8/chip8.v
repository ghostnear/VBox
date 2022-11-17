module chip8

// The documentations that were mainly used for this:
// https://github.com/chip-8/extensions
// https://github.com/trapexit/chip-8_documentation

// CHIP8 virtual machine structure.
[heap]
pub struct VM
{
pub mut:
	cpu CPU
	mem Memory
	gfx Display
	snd Audio
	inp Input
	tim Timers
	rom ROM
mut:
	emulation_thread &thread = unsafe { nil }
}

// Creates a new instance of the VM.
[inline]
pub fn new_vm() &VM
{
	v := &VM{
		inp: new_inp()
		cpu: new_cpu()
		mem: new_mem()
		gfx: new_dsp()
	}
	return v
}

// Starts the emulator on a new thread.
[inline]
pub fn (mut self VM) start()
{
	// Only if we don't have a thread already active start and set the flag.
	// If used coretly, it's very likely that this is true.
	if _likely_(self.emulation_thread == unsafe { nil })
	{
		self.emulation_thread = &(go self.internal_loop())
		self.cpu.execution_flag = true
		self.cpu.halt_flag = false
	}
}

// Waits for the execution thread to stop, then deletes it.
pub fn (mut self VM) wait_for_finish() bool
{
	// Do nothing if we are still running the thread or if it doesnt exist.
	if self.cpu.execution_flag == true || self.emulation_thread == unsafe { nil }
	{
		// We are still waiting
		return true
	}

	// TODO: figure out why this panics V sometimes.
	// self.emulation_thread.wait()
	
	self.emulation_thread = unsafe { nil }
	return false
}

// Marks the emulation thread as stopped, doesn't do any actual thread stopping.
// Use stop_and_wait() for that instead.
[inline]
pub fn (mut self VM) stop()
{
	self.cpu.execution_flag = false
}

// Reads a ROM file from the specified path.
[inline]
pub fn (mut self VM) load_rom(path string)
{
	self.rom.load_from_file(path)
	self.mem.load_rom(self.rom)
}

// Steps the CPU once, useful for debugging
fn (mut self VM) step_once()
{
	self.cpu.step(mut self)
}

// Steps the CPU for an arbitrary number of instructions, useful for the same debugging.
pub fn (mut self VM) step_multiple_times(times int)
{
	for index := times; index > 0; index--
	{
		self.step_once()
	}
}

// Internal loop that does the emulation on a different thread.
fn (mut self VM) internal_loop()
{
	// Infinite loop
	for {
		// If the cpu is not halted, then run. Very likely ofc.
		if _likely_(!self.cpu.halt_flag)
		{
			self.step_once()
		}

		// Do drawing only if required
		if self.gfx.draw_flag
		{
			self.gfx.render_to_terminal()
			self.gfx.draw_flag = false
		}

		// Stop entirely when we are forced to
		if _unlikely_(!self.cpu.execution_flag)
		{
			break
		}
	}
}