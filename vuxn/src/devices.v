module vuxn

import log

@[heap]
interface Device {
mut:
	write(address u8, data u8)
	read(address u8) u8
}

struct Devices {
mut:
	devices map[int]Device
}

fn (mut self Devices) write(address u8, data u8) {
	if address >> 4 !in self.devices {
		log.warn('Write call on invalid device 0x${address >> 4:01X} at index: 0x${address & 0xF:01X} with data: 0x${data:02X}.')
		return
	}
	self.devices[address >> 4].write(address & 0xF, data)
}

fn (mut self Devices) map_device(device Device, index int) {
	self.devices[index] = device
}

fn (mut self Devices) vwrite(condition bool, address u8, data u16) {
	if condition {
		self.write(address, u8(data >> 8))
		self.write(address + 1, u8(data & 0xFF))
		return
	}
	self.write(address, u8(data & 0xFF))
}

fn (mut self Devices) read(address u8) u8 {
	if address >> 4 !in self.devices {
		log.warn('Read call on invalid device 0x${address >> 4:01X} at index: 0x${address & 0xF:01X}.')
		return 0x00
	}
	return self.devices[address >> 4].read(address & 0xF)
}

fn (mut self Devices) vread(condition bool, address u8) u16 {
	if condition {
		return u16(self.read(address)) << 8 | u16(self.read(address + 1))
	}
	return u16(self.read(address))
}
