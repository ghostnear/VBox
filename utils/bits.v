module utils

[inline]
pub fn get_bit(number int, count int) int {
	return (number >> count) & 0b1
}

[inline]
pub fn set_bit(number &int, count int, value int) {
	unsafe {
		if value != 0 {
			*number |= (1 << count)
			return
		}
		*number &= ~(1 << count)
	}
}
