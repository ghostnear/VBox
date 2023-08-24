module emulator_common

import sdl_driver

interface Emulator {
mut:
	window &sdl_driver.Window
	draw()
	update()
}
