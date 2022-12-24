#!/usr/bin/env -S v

import os
import term

// Create build folder if it does not exist.
if !os.exists('../build') {
	os.chdir('..')!
	os.mkdir('build')!
	os.chdir('scripts')!
	println(term.warn_message('Build folder has been created as it did not exist before.'))
}

// OS check for extension.
mut extension := ''
if os.user_os() == 'windows' {
	extension = 'exe'
}

// Actually build the file.
if os.system('v .. -o VBox' + extension) != 0 {
	println(term.fail_message('Error while building the executable. Check the output for more info.'))
} else {
	os.mv('VBox', '../build/VBox')!
	println(term.ok_message('Executable built successful.'))
}
