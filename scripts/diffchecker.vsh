#!/bin/v

import os
import math

mut lines1 := os.read_lines(os.args[1]) or {
	panic("Couldn't open first file (${err}).")
}

mut lines2 := os.read_lines(os.args[2]) or {
	panic("Couldn't open second file (${err}).")
}

mut limit := os.args[3].int()
mut count := 0

for index := 0; index < math.min(lines1.len, lines2.len); index++ {
	if lines1[index] != lines2[index] {
		println("Lines at index ${index} are different!")
		println("${lines1[index]}\n${lines2[index]}\n")
		count++
	}

	if count == limit {
		break
	}
}
