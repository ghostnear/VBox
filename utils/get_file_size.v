module utils

import os

pub fn get_file_size(mut file os.File) int {
	file.seek(0, .end) or {}
	size := file.tell() or { 0 }
	file.seek(0, .start) or {}
	return int(size)
}
