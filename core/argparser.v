module core

import os

// TODO: print a help menu if using -h or --help.

// For the short version of the arguments.
const shortened_args = {
	'dm': 'display-mode'
	'p': 'platform'
	'r': 'rom'
}

// Contains all info about the currently specified command line arguments.
pub struct ArgParser {
mut:
	args map[string]string
}

// Returns the longer form and the value of the argument.
[inline]
fn solve_argument(input string) ?[]string {
	mut result := ['', '']

	// Parse the input into name and value (optional value, can be a flag for ex)

	// Long argument
	if input[0..2] == '--' {
		result = input[2..input.len].split('=')
	}
	// Short argument
	else if input[0..1] == '-' {
		result = input[1..input.len].split('=')
		result[0] = core.shortened_args[result[0]]
	}

	// Make sure the result is the right length.
	for result.len < 2 {
		result << 'set'
	}

	return result[0..2]
}

const result_index = 0

const result_value = 1

// Takes care of all the argument parsing for us.
pub fn parse_arguments() ArgParser {
	mut result := ArgParser{}
	for index := 1; index < os.args.len; index++ {
		mut parse_result := solve_argument(os.args[index]) or { ['', ''] }
		if parse_result[core.result_index] != '' {
			result.args[parse_result[core.result_index]] = parse_result[core.result_value]
		}
	}
	return result
}

// Checks if the argument has been set to a value or not.
[inline]
pub fn (self ArgParser) is_set(what string) bool {
	if what in self.args {
		return true
	}
	return false
}

// Gets the value of an argument or "" if it does not exist.
[inline]
pub fn (self ArgParser) get_value(what string) string {
	if what in self.args {
		return self.args[what]
	}
	return ''
}
