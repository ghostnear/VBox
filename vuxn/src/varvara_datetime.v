module vuxn

import log
import time

@[heap]
struct DateTime {
mut:
	parent &Emulator
}

fn (mut self DateTime) read(address u8) u8 {
	current_time := time.now()
	match address {
		0x00 {
			// Upper byte of year.
			return u8((current_time.year & 0xFF00) >> 8)
		}
		0x01 {
			// Lower byte of year.
			return u8(current_time.year & 0xFF)
		}
		0x02 {
			return u8(current_time.month)
		}
		0x03 {
			return u8(current_time.day)
		}
		0x04 {
			return u8(current_time.hour)
		}
		0x05 {
			return u8(current_time.minute)
		}
		0x06 {
			return u8(current_time.second)
		}
		else {
			log.warn('Unmapped DateTime read from 0x${address:01X}')
		}
	}
	return 0x00
}

fn (mut self DateTime) write(address u8, data u8) {
	log.warn('Unmapped DateTime write to 0x${address:01X} data 0x${data:02X}')
}
