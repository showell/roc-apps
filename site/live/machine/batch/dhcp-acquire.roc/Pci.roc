# Pci -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Machine

Pci :: [].{
	PciDevice := { pci_bus : I64, pci_dev : I64, pci_func : I64, pci_vendor : I64, pci_device_id : I64, pci_class : I64, pci_subclass : I64, pci_header_type : I64 }.{
		is_eq : Pci.PciDevice, Pci.PciDevice -> Bool
		is_eq = |a, b| eq_PciDevice(a, b)
	}
	PciBar := { bar_index : I64, bar_base : I64, bar_is_io : Bool, bar_is_64bit : Bool }.{
		is_eq : Pci.PciBar, Pci.PciBar -> Bool
		is_eq = |a, b| eq_PciBar(a, b)
	}
	PciScanResult := { devices : List(Pci.PciDevice), count : I64, truncated : Bool }.{
		is_eq : Pci.PciScanResult, Pci.PciScanResult -> Bool
		is_eq = |a, b| eq_PciScanResult(a, b)
	}
	PciWalk := { pw_devs : List(Pci.PciDevice), pw_cut : Bool }.{
		is_eq : Pci.PciWalk, Pci.PciWalk -> Bool
		is_eq = |a, b| eq_PciWalk(a, b)
	}

	pci_config_addr : I64
	pci_config_addr = 3320

	pci_config_data : I64
	pci_config_data = 3324

	pci_header_type_mask : I64
	pci_header_type_mask = 127

	pci_address : I64, I64, I64, I64 -> I64
	pci_address = |bus, device, func, offset| I64.bitwise_or(2147483648, I64.bitwise_or(I64.shl_wrap(bus, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(device, I64.to_u8_wrap(11)), I64.bitwise_or(I64.shl_wrap(func, I64.to_u8_wrap(8)), I64.bitwise_and(offset, 252)))))

	pci_scan_bus! : Machine.Machine, I64 => (Machine.Machine, Pci.PciScanResult)
	pci_scan_bus! = |machine, bus| pci_scan_loop!(machine, bus, 0, 0, [], 0)

	pci_scan_loop! : Machine.Machine, I64, I64, I64, List(Pci.PciDevice), I64 => (Machine.Machine, Pci.PciScanResult)
	pci_scan_loop! = |machine, bus, dev, func, acc, count| (if (dev >= 32) { (machine, Pci.PciScanResult.{ devices: acc, count: count, truncated: False }) } else { (if (func >= 8) { pci_scan_loop!(machine, bus, (dev + 1), 0, acc, count) } else { ({
		(machine1, vendor) = pci_read_vendor!(machine, bus, dev, func)
		(if (vendor == 65535) { (if (func == 0) { pci_scan_loop!(machine1, bus, (dev + 1), 0, acc, count) } else { pci_scan_loop!(machine1, bus, dev, (func + 1), acc, count) }) } else { ({
			(machine2, device_id) = pci_read_device_id!(machine1, bus, dev, func)
			(machine3, class_info) = pci_read_class!(machine2, bus, dev, func)
			(machine4, hdr_type) = pci_read_header_type!(machine3, bus, dev, func)
			entry = Pci.PciDevice.{ pci_bus: bus, pci_dev: dev, pci_func: func, pci_vendor: vendor, pci_device_id: device_id, pci_class: I64.bitwise_and(I64.shr_zf_wrap(class_info, I64.to_u8_wrap(8)), 255), pci_subclass: I64.bitwise_and(class_info, 255), pci_header_type: I64.bitwise_and(hdr_type, pci_header_type_mask) }
			multi : Bool
			multi = (I64.bitwise_and(hdr_type, 128) > 0)
			(if (func == 0) { (if multi { pci_scan_loop!(machine4, bus, dev, 1, List.append(acc, entry), (count + 1)) } else { pci_scan_loop!(machine4, bus, (dev + 1), 0, List.append(acc, entry), (count + 1)) }) } else { pci_scan_loop!(machine4, bus, dev, (func + 1), List.append(acc, entry), (count + 1)) })
		}) })
	}) }) })

	pci_scan_max_depth : I64
	pci_scan_max_depth = 3

	pci_sec_bus! : Machine.Machine, Pci.PciDevice => (Machine.Machine, I64)
	pci_sec_bus! = |machine, d| ({
		(machine1, machine__1) = pci_read_config!(machine, d.pci_bus, d.pci_dev, d.pci_func, 24)
		(machine1, I64.bitwise_and(I64.shr_zf_wrap(machine__1, I64.to_u8_wrap(8)), 255))
	})

	pci_scan_all! : Machine.Machine => (Machine.Machine, Pci.PciScanResult)
	pci_scan_all! = |machine| ({
		(machine2, machine__1) = ({
		(machine1, w) = pci_collect!(machine, 0, 0, Pci.PciWalk.{ pw_devs: [], pw_cut: False })
		(machine1, Pci.PciScanResult.{ devices: w.pw_devs, count: U64.to_i64_wrap(List.len(w.pw_devs)), truncated: w.pw_cut })
	})
		(machine2, machine__1)
	})

	pci_collect! : Machine.Machine, I64, I64, Pci.PciWalk => (Machine.Machine, Pci.PciWalk)
	pci_collect! = |machine, bus, depth, w| (if (depth > pci_scan_max_depth) { (machine, Pci.PciWalk.{ pw_devs: w.pw_devs, pw_cut: True }) } else { ({
		(machine1, s) = pci_scan_bus!(machine, bus)
		here = Pci.PciWalk.{ pw_devs: List.concat(w.pw_devs, s.devices), pw_cut: w.pw_cut }
		pci_bridges!(machine1, s.devices, s.count, 0, bus, depth, here)
	}) })

	pci_bridges! : Machine.Machine, List(Pci.PciDevice), I64, I64, I64, I64, Pci.PciWalk => (Machine.Machine, Pci.PciWalk)
	pci_bridges! = |machine, devs, n, i, bus, depth, w| (if (i >= n) { (machine, w) } else { (if ((List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).pci_header_type == 1) { pci_bridge_one!(machine, (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), devs, n, i, bus, depth, w) } else { pci_bridges!(machine, devs, n, (i + 1), bus, depth, w) }) })

	pci_bridge_one! : Machine.Machine, Pci.PciDevice, List(Pci.PciDevice), I64, I64, I64, I64, Pci.PciWalk => (Machine.Machine, Pci.PciWalk)
	pci_bridge_one! = |machine, d, devs, n, i, bus, depth, w| ({
		(machine1, sec) = pci_sec_bus!(machine, d)
		(if (sec > bus) { ({
			(machine2, sub) = pci_collect!(machine1, sec, (depth + 1), w)
			pci_bridges!(machine2, devs, n, (i + 1), bus, depth, sub)
		}) } else { pci_bridges!(machine1, devs, n, (i + 1), bus, depth, w) })
	})

	pci_read_config! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_config! = |machine, bus, dev, func, offset| ({
		addr : I64
		addr = pci_address(bus, dev, func, offset)
		pci_config_read_raw!(machine, addr, offset)
	})

	pci_config_read_raw! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	pci_config_read_raw! = |machine, addr, _offset| ({
		(machine3, machine__2) = ({
		(machine1, w) = Machine.port_out_32!(machine, pci_config_addr, addr)
		({
			(machine2, machine__1) = Machine.port_in_32!(machine1, pci_config_data)
			(machine2, (w + machine__1))
		})
	})
		(machine3, machine__2)
	})

	pci_read_vendor! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_vendor! = |machine, bus, dev, func| ({
		(machine1, machine__1) = pci_read_config!(machine, bus, dev, func, 0)
		(machine1, I64.bitwise_and(machine__1, 65535))
	})

	pci_read_device_id! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_device_id! = |machine, bus, dev, func| ({
		(machine1, machine__1) = pci_read_config!(machine, bus, dev, func, 0)
		(machine1, I64.shr_zf_wrap(machine__1, I64.to_u8_wrap(16)))
	})

	pci_read_class! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_class! = |machine, bus, dev, func| ({
		(machine2, machine__1) = ({
		(machine1, reg) = pci_read_config!(machine, bus, dev, func, 8)
		(machine1, I64.shr_zf_wrap(reg, I64.to_u8_wrap(16)))
	})
		(machine2, machine__1)
	})

	pci_read_header_type! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_header_type! = |machine, bus, dev, func| ({
		(machine2, machine__1) = ({
		(machine1, reg) = pci_read_config!(machine, bus, dev, func, 12)
		(machine1, I64.bitwise_and(I64.shr_zf_wrap(reg, I64.to_u8_wrap(16)), 255))
	})
		(machine2, machine__1)
	})

	pci_read_bar! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_bar! = |machine, bus, dev, func, bar_idx| pci_read_config!(machine, bus, dev, func, (16 + (bar_idx * 4)))

	pci_parse_bar! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, Pci.PciBar)
	pci_parse_bar! = |machine, bus, dev, func, bar_idx| ({
		(machine2, machine__1) = ({
		(machine1, raw) = pci_read_bar!(machine, bus, dev, func, bar_idx)
		is_io : Bool
		is_io = (I64.bitwise_and(raw, 1) == 1)
		is_64 : Bool
		is_64 = (if is_io { False } else { (I64.bitwise_and(I64.shr_zf_wrap(raw, I64.to_u8_wrap(1)), 3) == 2) })
		base : I64
		base = (if is_io { I64.bitwise_and(raw, 65532) } else { I64.bitwise_and(raw, 4294967280) })
		(machine1, Pci.PciBar.{ bar_index: bar_idx, bar_base: base, bar_is_io: is_io, bar_is_64bit: is_64 })
	})
		(machine2, machine__1)
	})

	pci_write_config! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	pci_write_config! = |machine, bus, dev, func, offset, value| ({
		(machine3, machine__2) = ({
		addr : I64
		addr = pci_address(bus, dev, func, offset)
		(machine1, w) = Machine.port_out_32!(machine, pci_config_addr, addr)
		({
			(machine2, machine__1) = Machine.port_out_32!(machine1, pci_config_data, value)
			(machine2, (w + machine__1))
		})
	})
		(machine3, machine__2)
	})

	pci_enable_device! : Machine.Machine, Pci.PciDevice => (Machine.Machine, I64)
	pci_enable_device! = |machine, d| ({
		(machine1, cmd) = pci_read_config!(machine, d.pci_bus, d.pci_dev, d.pci_func, 4)
		new_cmd : I64
		new_cmd = I64.bitwise_or(cmd, 7)
		pci_write_config!(machine1, d.pci_bus, d.pci_dev, d.pci_func, 4, new_cmd)
	})

	eq_PciDevice : Pci.PciDevice, Pci.PciDevice -> Bool
	eq_PciDevice = |ex, ey| ((((((((ex.pci_bus == ey.pci_bus) and (ex.pci_dev == ey.pci_dev)) and (ex.pci_func == ey.pci_func)) and (ex.pci_vendor == ey.pci_vendor)) and (ex.pci_device_id == ey.pci_device_id)) and (ex.pci_class == ey.pci_class)) and (ex.pci_subclass == ey.pci_subclass)) and (ex.pci_header_type == ey.pci_header_type))

	eq_PciBar : Pci.PciBar, Pci.PciBar -> Bool
	eq_PciBar = |ex, ey| ((((ex.bar_index == ey.bar_index) and (ex.bar_base == ey.bar_base)) and (ex.bar_is_io == ey.bar_is_io)) and (ex.bar_is_64bit == ey.bar_is_64bit))

	eq_PciScanResult : Pci.PciScanResult, Pci.PciScanResult -> Bool
	eq_PciScanResult = |ex, ey| (((ex.devices == ey.devices) and (ex.count == ey.count)) and (ex.truncated == ey.truncated))

	eq_PciWalk : Pci.PciWalk, Pci.PciWalk -> Bool
	eq_PciWalk = |ex, ey| ((ex.pw_devs == ey.pw_devs) and (ex.pw_cut == ey.pw_cut))
}
