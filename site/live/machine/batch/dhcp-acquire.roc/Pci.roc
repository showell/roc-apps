# Pci -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Machine
import Maybe

Pci :: [].{
	PciDevice : { pci_bus : I64, pci_dev : I64, pci_func : I64, pci_vendor : I64, pci_device_id : I64, pci_class : I64, pci_subclass : I64, pci_header_type : I64 }
	PciBar : { bar_index : I64, bar_base : I64, bar_is_io : Bool, bar_is_64bit : Bool }
	PciScanResult : { devices : List(Pci.PciDevice), count : I64, truncated : Bool }
	PciWalk : { pw_devs : List(Pci.PciDevice), pw_cut : Bool }

	pci_config_addr : I64
	pci_config_addr = 3320

	pci_config_data : I64
	pci_config_data = 3324

	pci_vendor_nvidia : I64
	pci_vendor_nvidia = 4318

	pci_vendor_virtio : I64
	pci_vendor_virtio = 6900

	pci_header_type_mask : I64
	pci_header_type_mask = 127

	pci_address : I64, I64, I64, I64 -> I64
	pci_address = |bus, device, func, offset| I64.bitwise_or(2147483648, I64.bitwise_or(I64.shl_wrap(bus, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(device, I64.to_u8_wrap(11)), I64.bitwise_or(I64.shl_wrap(func, I64.to_u8_wrap(8)), I64.bitwise_and(offset, 252)))))

	pci_scan_bus! : Machine.Machine, I64 => (Machine.Machine, Pci.PciScanResult)
	pci_scan_bus! = |machine, bus| pci_scan_loop!(machine, bus, 0, 0, [], 0)

	pci_scan_loop! : Machine.Machine, I64, I64, I64, List(Pci.PciDevice), I64 => (Machine.Machine, Pci.PciScanResult)
	pci_scan_loop! = |machine, bus, dev, func, acc, count| (if (dev >= 32) { (machine, { devices: acc, count: count, truncated: False }) } else { (if (func >= 8) { pci_scan_loop!(machine, bus, (dev + 1), 0, acc, count) } else { ({
		(machine1, vendor) = pci_read_vendor!(machine, bus, dev, func)
		(if (vendor == 65535) { (if (func == 0) { pci_scan_loop!(machine1, bus, (dev + 1), 0, acc, count) } else { pci_scan_loop!(machine1, bus, dev, (func + 1), acc, count) }) } else { ({
			(machine2, device_id) = pci_read_device_id!(machine1, bus, dev, func)
			(machine3, class_info) = pci_read_class!(machine2, bus, dev, func)
			(machine4, hdr_type) = pci_read_header_type!(machine3, bus, dev, func)
			entry = { pci_bus: bus, pci_dev: dev, pci_func: func, pci_vendor: vendor, pci_device_id: device_id, pci_class: I64.bitwise_and(I64.shr_zf_wrap(class_info, I64.to_u8_wrap(8)), 255), pci_subclass: I64.bitwise_and(class_info, 255), pci_header_type: I64.bitwise_and(hdr_type, pci_header_type_mask) }
			multi = (I64.bitwise_and(hdr_type, 128) > 0)
			(if (func == 0) { (if multi { pci_scan_loop!(machine4, bus, dev, 1, List.append(acc, entry), (count + 1)) } else { pci_scan_loop!(machine4, bus, (dev + 1), 0, List.append(acc, entry), (count + 1)) }) } else { pci_scan_loop!(machine4, bus, dev, (func + 1), List.append(acc, entry), (count + 1)) })
		}) })
	}) }) })

	pci_scan_max_depth : I64
	pci_scan_max_depth = 3

	pci_sec_bus! : Machine.Machine, Pci.PciDevice => (Machine.Machine, I64)
	pci_sec_bus! = |machine, d| ({
		(machine1, machine__11) = pci_read_config!(machine, d.pci_bus, d.pci_dev, d.pci_func, 24)
		(machine1, I64.bitwise_and(I64.shr_zf_wrap(machine__11, I64.to_u8_wrap(8)), 255))
	})

	pci_scan_all! : Machine.Machine => (Machine.Machine, Pci.PciScanResult)
	pci_scan_all! = |machine| ({
		(machine2, machine__12) = ({
		(machine1, w) = pci_collect!(machine, 0, 0, { pw_devs: [], pw_cut: False })
		(machine1, { devices: w.pw_devs, count: U64.to_i64_wrap(List.len(w.pw_devs)), truncated: w.pw_cut })
	})
		(machine2, machine__12)
	})

	pci_collect! : Machine.Machine, I64, I64, Pci.PciWalk => (Machine.Machine, Pci.PciWalk)
	pci_collect! = |machine, bus, depth, w| (if (depth > pci_scan_max_depth) { (machine, { pw_devs: w.pw_devs, pw_cut: True }) } else { ({
		(machine1, s) = pci_scan_bus!(machine, bus)
		here = { pw_devs: List.concat(w.pw_devs, s.devices), pw_cut: w.pw_cut }
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
		addr = pci_address(bus, dev, func, offset)
		pci_config_read_raw!(machine, addr, offset)
	})

	pci_config_read_raw! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	pci_config_read_raw! = |machine, addr, _offset| ({
		(machine3, machine__14) = ({
		(machine1, w) = Machine.port_out_32!(machine, pci_config_addr, addr)
		({
			(machine2, machine__13) = Machine.port_in_32!(machine1, pci_config_data)
			(machine2, (w + machine__13))
		})
	})
		(machine3, machine__14)
	})

	pci_bar_size! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	pci_bar_size! = |machine, bus, dev, func, bar_offset| ({
		(machine5, machine__15) = ({
		(machine1, base) = pci_read_config!(machine, bus, dev, func, bar_offset)
		(machine2, _q) = pci_write_config!(machine1, bus, dev, func, bar_offset, (0 - 1))
		(machine3, mask) = pci_read_config!(machine2, bus, dev, func, bar_offset)
		(machine4, _r) = pci_write_config!(machine3, bus, dev, func, bar_offset, base)
		(machine4, (if (mask == 0) { 0 } else { I64.bitwise_and((0 - I64.bitwise_and(mask, (0 - 16))), 4294967295) }))
	})
		(machine5, machine__15)
	})

	pci_read_vendor! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_vendor! = |machine, bus, dev, func| ({
		(machine1, machine__16) = pci_read_config!(machine, bus, dev, func, 0)
		(machine1, I64.bitwise_and(machine__16, 65535))
	})

	pci_read_device_id! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_device_id! = |machine, bus, dev, func| ({
		(machine1, machine__17) = pci_read_config!(machine, bus, dev, func, 0)
		(machine1, I64.shr_zf_wrap(machine__17, I64.to_u8_wrap(16)))
	})

	pci_read_class! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_class! = |machine, bus, dev, func| ({
		(machine2, machine__18) = ({
		(machine1, reg) = pci_read_config!(machine, bus, dev, func, 8)
		(machine1, I64.shr_zf_wrap(reg, I64.to_u8_wrap(16)))
	})
		(machine2, machine__18)
	})

	pci_read_header_type! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_header_type! = |machine, bus, dev, func| ({
		(machine2, machine__19) = ({
		(machine1, reg) = pci_read_config!(machine, bus, dev, func, 12)
		(machine1, I64.bitwise_and(I64.shr_zf_wrap(reg, I64.to_u8_wrap(16)), 255))
	})
		(machine2, machine__19)
	})

	pci_read_bar! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	pci_read_bar! = |machine, bus, dev, func, bar_idx| pci_read_config!(machine, bus, dev, func, (16 + (bar_idx * 4)))

	pci_find_vendor : Pci.PciScanResult, I64 -> Maybe.Maybe(Pci.PciDevice)
	pci_find_vendor = |scan, vendor| pci_find_vendor_loop(scan.devices, vendor, 0, scan.count)

	pci_find_vendor_loop : List(Pci.PciDevice), I64, I64, I64 -> Maybe.Maybe(Pci.PciDevice)
	pci_find_vendor_loop = |devs, vendor, i, len| (if (i >= len) { None } else { ({
		d = (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (d.pci_vendor == vendor) { Just(d) } else { pci_find_vendor_loop(devs, vendor, (i + 1), len) })
	}) })

	pci_find_class : Pci.PciScanResult, I64, I64 -> Maybe.Maybe(Pci.PciDevice)
	pci_find_class = |scan, cls, subcls| pci_find_class_loop(scan.devices, cls, subcls, 0, scan.count)

	pci_find_class_loop : List(Pci.PciDevice), I64, I64, I64, I64 -> Maybe.Maybe(Pci.PciDevice)
	pci_find_class_loop = |devs, cls, subcls, i, len| (if (i >= len) { None } else { ({
		d = (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (d.pci_class == cls) { (if (d.pci_subclass == subcls) { Just(d) } else { pci_find_class_loop(devs, cls, subcls, (i + 1), len) }) } else { pci_find_class_loop(devs, cls, subcls, (i + 1), len) })
	}) })

	pci_index_class : Pci.PciScanResult, I64, I64, I64 -> I64
	pci_index_class = |scan, cls, subcls, from| pci_index_class_loop(scan.devices, cls, subcls, from, scan.count)

	pci_index_class_loop : List(Pci.PciDevice), I64, I64, I64, I64 -> I64
	pci_index_class_loop = |devs, cls, subcls, i, len| (if (i >= len) { (-1) } else { ({
		d = (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (d.pci_class == cls) { (if (d.pci_subclass == subcls) { i } else { pci_index_class_loop(devs, cls, subcls, (i + 1), len) }) } else { pci_index_class_loop(devs, cls, subcls, (i + 1), len) })
	}) })

	pci_count_class : Pci.PciScanResult, I64, I64 -> I64
	pci_count_class = |scan, cls, subcls| pci_count_class_loop(scan.devices, cls, subcls, 0, scan.count, 0)

	pci_count_class_loop : List(Pci.PciDevice), I64, I64, I64, I64, I64 -> I64
	pci_count_class_loop = |devs, cls, subcls, i, len, n| (if (i >= len) { n } else { ({
		d = (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (d.pci_class == cls) { (if (d.pci_subclass == subcls) { pci_count_class_loop(devs, cls, subcls, (i + 1), len, (n + 1)) } else { pci_count_class_loop(devs, cls, subcls, (i + 1), len, n) }) } else { pci_count_class_loop(devs, cls, subcls, (i + 1), len, n) })
	}) })

	pci_find_device : Pci.PciScanResult, I64, I64 -> Maybe.Maybe(Pci.PciDevice)
	pci_find_device = |scan, vendor, device_id| pci_find_dev_loop(scan.devices, vendor, device_id, 0, scan.count)

	pci_find_dev_loop : List(Pci.PciDevice), I64, I64, I64, I64 -> Maybe.Maybe(Pci.PciDevice)
	pci_find_dev_loop = |devs, vendor, did, i, len| (if (i >= len) { None } else { ({
		d = (List.get(devs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (d.pci_vendor == vendor) { (if (d.pci_device_id == did) { Just(d) } else { pci_find_dev_loop(devs, vendor, did, (i + 1), len) }) } else { pci_find_dev_loop(devs, vendor, did, (i + 1), len) })
	}) })

	pci_parse_bar! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, Pci.PciBar)
	pci_parse_bar! = |machine, bus, dev, func, bar_idx| ({
		(machine2, machine__20) = ({
		(machine1, raw) = pci_read_bar!(machine, bus, dev, func, bar_idx)
		is_io = (I64.bitwise_and(raw, 1) == 1)
		is_64 = (if is_io { False } else { (I64.bitwise_and(I64.shr_zf_wrap(raw, I64.to_u8_wrap(1)), 3) == 2) })
		base = (if is_io { I64.bitwise_and(raw, 65532) } else { I64.bitwise_and(raw, 4294967280) })
		(machine1, { bar_index: bar_idx, bar_base: base, bar_is_io: is_io, bar_is_64bit: is_64 })
	})
		(machine2, machine__20)
	})

	pci_write_config! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	pci_write_config! = |machine, bus, dev, func, offset, value| ({
		(machine3, machine__22) = ({
		addr = pci_address(bus, dev, func, offset)
		(machine1, w) = Machine.port_out_32!(machine, pci_config_addr, addr)
		({
			(machine2, machine__21) = Machine.port_out_32!(machine1, pci_config_data, value)
			(machine2, (w + machine__21))
		})
	})
		(machine3, machine__22)
	})

	pci_enable_device! : Machine.Machine, Pci.PciDevice => (Machine.Machine, I64)
	pci_enable_device! = |machine, d| ({
		(machine1, cmd) = pci_read_config!(machine, d.pci_bus, d.pci_dev, d.pci_func, 4)
		new_cmd = I64.bitwise_or(cmd, 7)
		pci_write_config!(machine1, d.pci_bus, d.pci_dev, d.pci_func, 4, new_cmd)
	})

	format_pci_device : Pci.PciDevice -> Str
	format_pci_device = |d| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(pci_hex16(d.pci_vendor), ":"), pci_hex16(d.pci_device_id)), " class="), I64.to_str(d.pci_class)), "."), I64.to_str(d.pci_subclass)), " at "), I64.to_str(d.pci_bus)), ":"), I64.to_str(d.pci_dev)), "."), I64.to_str(d.pci_func))

	pci_hex16 : I64 -> Str
	pci_hex16 = |v| Str.concat(Str.concat(Str.concat(pci_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(12)), 15)), pci_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 15))), pci_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(4)), 15))), pci_nib(I64.bitwise_and(v, 15)))

	pci_nib : I64 -> Str
	pci_nib = |n| (if (n == 0) { "0" } else { (if (n == 1) { "1" } else { (if (n == 2) { "2" } else { (if (n == 3) { "3" } else { (if (n == 4) { "4" } else { (if (n == 5) { "5" } else { (if (n == 6) { "6" } else { (if (n == 7) { "7" } else { (if (n == 8) { "8" } else { (if (n == 9) { "9" } else { (if (n == 10) { "a" } else { (if (n == 11) { "b" } else { (if (n == 12) { "c" } else { (if (n == 13) { "d" } else { (if (n == 14) { "e" } else { "f" }) }) }) }) }) }) }) }) }) }) }) }) }) }) })
}
