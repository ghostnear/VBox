#!/usr/bin/env -S v

import os
import term

const_build_path := './build.vsh'
const_paths := {
	'windows': '../build/VBox.exe'
	'linux':   '../build/VBox'
}

// Build exe if not already built.
if !os.exists(const_paths['windows']) && !os.exists(const_paths['linux']) {
	println(term.warn_message('Executable was not built. Building...'))
	os.system(const_build_path)
}

os.chdir('..')!
os.chdir('build')!

if os.args.len != 3
{
	print('${ term.fail_message("run.sh format invalid!") }\n')
	print('${ term.warn_message("Usage: run.vsh <emulator_type> <emulated_file_path>") }\n')
}
else
{
	os.system(const_paths[os.user_os()] + ' -p=${ os.args[1] } -r="${ os.args[2] }"')
}