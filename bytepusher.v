module vbox_bytepusher

import ui

/*	Struct Definition	*/
pub struct BytePusherVM {
mut:
	running bool
	emu_thread thread
}

/*	Private Methods	*/

// Thread function called by run()
fn (mut v BytePusherVM) thread_func() {
	// While thread is not stopped
	for v.running {
		ui.message_box("In BytePusher thread!")
	}
}

/*	Public Methods	*/

// Initialises the VM with the default values
pub fn (mut v BytePusherVM) init() {
	v.running = false
}

// This starts a thread where the VM will run
pub fn (mut v BytePusherVM) run() {
	// Do not start another thread if there is one running atm
	if v.running == false {
		v.running = true
		v.emu_thread = go v.thread_func()
	}
}

// Sends the stop signal to the thread and waits for it to stop
pub fn (mut v BytePusherVM) stop() {
	// Do not stop the thread if already running
	if v.running == true {
		v.running = false
		v.emu_thread.wait()
	}
}