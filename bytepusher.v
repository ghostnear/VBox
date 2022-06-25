module vbox_bytepusher

import time { new_stopwatch, sleep }
import vbox_bytepusher_state { BytePusherState }

/*	Struct Definition	*/
pub struct BytePusherVM {
mut:
	emu_state	BytePusherState
	running 	bool
	emu_thread 	thread	
}

/*	Private Methods	*/

// Thread function called by run()
fn (mut v BytePusherVM) thread_func() {
	mut sw := new_stopwatch()
	mut timer := f64(0)

	// While thread is not stopped
	for v.running {
		// Outer loop
		timer += sw.elapsed().seconds()
		sw.restart()

		// 60 hz loop
		for timer >= 1.0 / 60 {
			// TODO: poll keys

			// Inner loop
			v.emu_state.inner_loop()

			// TODO: render
			timer -= 1.0 / 60
		}

		// Wait until the next 60 hz
		sleep(100000000.0 / 6 - timer)
	}
}

/*	Public Methods	*/

// Initialises the VM with the default values
pub fn (mut v BytePusherVM) init() {
	v.running = false
	v.emu_state.init()
}

// Loads the ROM from path - sends it to the state
pub fn (mut v BytePusherVM) load(path string) {
	v.emu_state.load(path)
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