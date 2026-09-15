# Pci -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Mem

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

	pci_scan_bus! : Mem.Mem, I64 => (Mem.Mem, Pci.PciScanResult)
	pci_scan_bus! = |_, _| crash("`pci-scan-bus` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_scan_loop! : Mem.Mem, I64, I64, I64, List(Pci.PciDevice), I64 => (Mem.Mem, Pci.PciScanResult)
	pci_scan_loop! = |_, _, _, _, _, _| crash("`pci-scan-loop` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_scan_max_depth : I64
	pci_scan_max_depth = 3

	pci_sec_bus! : Mem.Mem, Pci.PciDevice => (Mem.Mem, I64)
	pci_sec_bus! = |_, _| crash("`pci-sec-bus` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_scan_all! : Mem.Mem => (Mem.Mem, Pci.PciScanResult)
	pci_scan_all! = |_| crash("`pci-scan-all` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_collect! : Mem.Mem, I64, I64, Pci.PciWalk => (Mem.Mem, Pci.PciWalk)
	pci_collect! = |_, _, _, _| crash("`pci-collect` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_bridges! : Mem.Mem, List(Pci.PciDevice), I64, I64, I64, I64, Pci.PciWalk => (Mem.Mem, Pci.PciWalk)
	pci_bridges! = |_, _, _, _, _, _, _| crash("`pci-bridges` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_bridge_one! : Mem.Mem, Pci.PciDevice, List(Pci.PciDevice), I64, I64, I64, I64, Pci.PciWalk => (Mem.Mem, Pci.PciWalk)
	pci_bridge_one! = |_, _, _, _, _, _, _, _| crash("`pci-bridge-one` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_read_config! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	pci_read_config! = |_, _, _, _, _| crash("`pci-read-config` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_config_read_raw! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	pci_config_read_raw! = |_, _, _| crash("`pci-config-read-raw` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_bar_size! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	pci_bar_size! = |_, _, _, _, _| crash("`pci-bar-size` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_read_vendor! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	pci_read_vendor! = |_, _, _, _| crash("`pci-read-vendor` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_read_device_id! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	pci_read_device_id! = |_, _, _, _| crash("`pci-read-device-id` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_read_class! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	pci_read_class! = |_, _, _, _| crash("`pci-read-class` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_read_header_type! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	pci_read_header_type! = |_, _, _, _| crash("`pci-read-header-type` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_read_bar! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	pci_read_bar! = |_, _, _, _, _| crash("`pci-read-bar` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

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

	pci_parse_bar! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, Pci.PciBar)
	pci_parse_bar! = |_, _, _, _, _| crash("`pci-parse-bar` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_write_config! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	pci_write_config! = |_, _, _, _, _, _| crash("`pci-write-config` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	pci_enable_device! : Mem.Mem, Pci.PciDevice => (Mem.Mem, I64)
	pci_enable_device! = |_, _| crash("`pci-enable-device` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	format_pci_device : Pci.PciDevice -> Str
	format_pci_device = |d| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(pci_hex16(d.pci_vendor), ":"), pci_hex16(d.pci_device_id)), " class="), I64.to_str(d.pci_class)), "."), I64.to_str(d.pci_subclass)), " at "), I64.to_str(d.pci_bus)), ":"), I64.to_str(d.pci_dev)), "."), I64.to_str(d.pci_func))

	pci_hex16 : I64 -> Str
	pci_hex16 = |v| Str.concat(Str.concat(Str.concat(pci_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(12)), 15)), pci_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 15))), pci_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(4)), 15))), pci_nib(I64.bitwise_and(v, 15)))

	pci_nib : I64 -> Str
	pci_nib = |n| (if (n == 0) { "0" } else { (if (n == 1) { "1" } else { (if (n == 2) { "2" } else { (if (n == 3) { "3" } else { (if (n == 4) { "4" } else { (if (n == 5) { "5" } else { (if (n == 6) { "6" } else { (if (n == 7) { "7" } else { (if (n == 8) { "8" } else { (if (n == 9) { "9" } else { (if (n == 10) { "a" } else { (if (n == 11) { "b" } else { (if (n == 12) { "c" } else { (if (n == 13) { "d" } else { (if (n == 14) { "e" } else { "f" }) }) }) }) }) }) }) }) }) }) }) }) }) }) })
}
