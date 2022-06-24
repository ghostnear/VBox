module main

import vbox_gui { GUIWindow }
import vbox_bytepusher { BytePusherVM }

fn main() {
	mut gui_window := GUIWindow{}

	gui_window.init()
	gui_window.set_title("VBox Manager")

	mut test_vm := BytePusherVM{}
	test_vm.init()
	test_vm.run()

	gui_window.run()

	test_vm.stop()
}