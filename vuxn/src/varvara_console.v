module vuxn

import log

@[heap]
struct Console {
mut:
	parent &Emulator
	vector []u8 = []u8{len: 2, cap: 2, init: 0x00}
}

fn (mut self Console) read(address u8) u8 {
	match address {
		0x00...0x01 {
			return self.vector[address]
		}
		0x07 {
			log.warn('Unimplemented console read: [0x07]')
			return 0x00
		}
		else {
			log.warn('Unmapped console read: [0x${address:02X}]')
			return 0x00
		}
	}
}

fn (mut self Console) write(address u8, data u8) {
	match address {
		0x00...0x01 {
			self.vector[address] = data
		}
		0x08 {
			if data == 0x0A {
				print('\n')
				return
			}
			print('${data:c}')
		}
		0x09 {
			if data == 0x0A {
				eprint('\n')
				return
			}
			eprint('${data:c}')
		}
		else {
			log.warn('Unmapped console write: [0x${address:02X}]: 0x${data:02X}')
		}
	}
}
