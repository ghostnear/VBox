module chip8

// CHIP8 virtual machine configuration.
pub struct VMConfig
{
	
}

// CHIP8 virtual machine structure.
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
	emulation_thread &thread = unsafe { nil }
}

// Creates a new instance of the VM.
pub fn new_vm() &VM
{
	v := &VM{
		cpu: new_cpu()
	}
	return v
}

// Starts the emulator on a new thread.
pub fn (mut self VM) start()
{
	// Only if we don't have a thread already active start and set the flag
	if self.emulation_thread == unsafe { nil }
	{
		self.emulation_thread = &(go self.internal_loop())
		self.cpu.execution_flag = true
		self.cpu.halt_flag = false
	}
}

// Waits for the execution thread to stop, then deletes it.
pub fn (mut self VM) wait_for_finish()
{
	if self.cpu.execution_flag == true
	{
		return
	}

	self.emulation_thread.wait()
	self.emulation_thread = unsafe { nil }
}

// Marks the emulation thread as stopped, doesn't do any actual thread stopping.
// Use stop_and_wait() for that instead.
pub fn (mut self VM) stop()
{
	self.cpu.execution_flag = false
}

// Reads a ROM file from the specified path.
pub fn (mut self VM) load_rom(path string)
{
	self.rom.load_from_file(path)
}

// Internal loop that does the emulation on a different thread.
fn (mut self VM) internal_loop()
{
	// Infinite loop
	for {
		// If the cpu is not halted, then run
		if !self.cpu.halt_flag
		{
			self.cpu.step(self)
		}

		// Stop entirely when we are forced to
		if !self.cpu.execution_flag
		{
			break
		}
	}
}