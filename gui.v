module vbox_gui

import ui
import vbox_utils { Vec2 }

/*	Struct Definition	*/
pub struct GUIWindow
{
mut:
	ptr		&ui.Window = 0
	title 	string
	size	Vec2
}

/*	Private Methods	*/

// Updates the native ui window's title
fn (mut w GUIWindow) update_title() {
	mut win_ptr := w.get_ptr()
	win_ptr.set_title(w.title)
	// ^
	// TODO: find out why the title is not changed in the native window
}

/*	Public Methods	*/

// Initialises the window with default values
pub fn (mut w GUIWindow) init() {
	w.ptr = ui.window(
		width: 960
		height: 540
		title: '<null>'
		resizable: true
	)
	w.title = '<null>'
	w.size = Vec2{960, 540}
}

// Gets the workable pointer from the struct
pub fn (mut w GUIWindow) get_ptr() &ui.Window {
	return w.ptr
}

// Sets the window title
pub fn (mut w GUIWindow) set_title(newTitle string) {
	w.title = newTitle
	w.update_title()
}

// Gets window title
pub fn (mut w GUIWindow) get_title() string {
	return w.title
}

// TODO: getters and setters for size

// Runs the main loop using ui
pub fn (mut w GUIWindow) run() {
	ui.run(w.get_ptr())
}