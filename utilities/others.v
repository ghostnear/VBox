module utilities

import sdl

[inline]
pub fn get_sdl_error() string {
	unsafe {
		return cstring_to_vstring(sdl.get_error())
	}
}
