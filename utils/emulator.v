module utils

import sdl
import sdl_driver

// This file contains the emulator interface.

interface Emulator {
mut:
	window &sdl_driver.Window
	set_window(&sdl_driver.Window)
	draw()
	update()
	is_running() bool
	on_event(&sdl.Event)
}
