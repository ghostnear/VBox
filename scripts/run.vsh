#!/usr/bin/env -S v

import os
import term

const_build_paths := './build.vsh'
const_paths := {
	'windows': '../build/VBox.exe'
	'linux':   '../build/VBox'
}

// Build exe if not already built.
if !os.exists(const_paths['windows']) && !os.exists(const_paths['linux']) {
	println(term.warn_message('Executable was not built. Building...'))
	os.system(const_build_paths)
}

os.chdir("..")!
os.chdir("build")!
os.system(const_paths[os.user_os()])
