# UsbHid -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text
import Usb

UsbHid :: [].{
	HidInterface : { hi_number : I64, hi_subclass : I64, hi_protocol : I64, hi_ep_in_addr : I64, hi_ep_out_addr : I64, hi_ep_in_max : I64, hi_ep_out_max : I64, hi_report_size : I64 }
	HidDevice : { hd_vendor : I64, hd_product : I64, hd_slot : I64, hd_interfaces : List(UsbHid.HidInterface), hd_interface_count : I64, hd_keyboard_if : I64, hd_raw_if : I64 }

	hid_class : I64
	hid_class = 3

	hid_subclass_none : I64
	hid_subclass_none = 0

	hid_subclass_boot : I64
	hid_subclass_boot = 1

	hid_protocol_keyboard : I64
	hid_protocol_keyboard = 1

	hid_protocol_mouse : I64
	hid_protocol_mouse = 2

	hid_desc_type_hid : I64
	hid_desc_type_hid = 33

	hid_desc_type_report : I64
	hid_desc_type_report = 34

	hid_req_get_report : I64
	hid_req_get_report = 1

	hid_req_get_idle : I64
	hid_req_get_idle = 2

	hid_req_get_protocol : I64
	hid_req_get_protocol = 3

	hid_req_set_report : I64
	hid_req_set_report = 9

	hid_req_set_idle : I64
	hid_req_set_idle = 10

	hid_req_set_protocol : I64
	hid_req_set_protocol = 11

	hid_report_type_input : I64
	hid_report_type_input = 1

	hid_report_type_output : I64
	hid_report_type_output = 2

	hid_report_type_feature : I64
	hid_report_type_feature = 3

	hid_interface_empty : UsbHid.HidInterface
	hid_interface_empty = { hi_number: 0, hi_subclass: 0, hi_protocol: 0, hi_ep_in_addr: 0, hi_ep_out_addr: 0, hi_ep_in_max: 0, hi_ep_out_max: 0, hi_report_size: 64 }

	hid_device_new : I64, I64, I64 -> UsbHid.HidDevice
	hid_device_new = |vendor, product, slot| { hd_vendor: vendor, hd_product: product, hd_slot: slot, hd_interfaces: [], hd_interface_count: 0, hd_keyboard_if: (-1), hd_raw_if: (-1) }

	hid_scan_interfaces : List(I64), I64 -> List(UsbHid.HidInterface)
	hid_scan_interfaces = |config_desc, total_len| ({
		n = U64.to_i64_wrap(List.len(config_desc))
		hid_scan_loop(config_desc, 0, (if (total_len > n) { n } else { total_len }), [], None)
	})

	hid_scan_loop : List(I64), I64, I64, List(UsbHid.HidInterface), Maybe.Maybe(UsbHid.HidInterface) -> List(UsbHid.HidInterface)
	hid_scan_loop = |desc, offset, total, acc, current| (if ((offset + 2) > total) { (match current {
		Just(iface) => List.append(acc, iface)
		None => acc
	}) } else { ({
		desc_len = (List.get(desc, I64.to_u64_wrap(offset)) ?? crash("list-at out of range"))
		desc_type = (List.get(desc, I64.to_u64_wrap((offset + 1))) ?? crash("list-at out of range"))
		(if (desc_len == 0) { acc } else { (if (desc_type == 4) { ({
			iface = Usb.usb_parse_interface(desc, offset)
			(if (iface.if_class == hid_class) { ({
				new_hid = { hi_number: iface.if_number, hi_subclass: iface.if_subclass, hi_protocol: iface.if_protocol, hi_ep_in_addr: 0, hi_ep_out_addr: 0, hi_ep_in_max: 0, hi_ep_out_max: 0, hi_report_size: 64 }
				acc2 = (match current {
					Just(prev) => List.append(acc, prev)
					None => acc
				})
				hid_scan_loop(desc, (offset + desc_len), total, acc2, Just(new_hid))
			}) } else { hid_scan_loop(desc, (offset + desc_len), total, acc, current) })
		}) } else { (if (desc_type == 5) { ({
			ep = Usb.usb_parse_endpoint(desc, offset)
			(match current {
				Just(iface) => hid_scan_loop(desc, (offset + desc_len), total, acc, Just(hid_add_endpoint(iface, ep)))
				None => hid_scan_loop(desc, (offset + desc_len), total, acc, current)
			})
		}) } else { hid_scan_loop(desc, (offset + desc_len), total, acc, current) }) }) })
	}) })

	hid_add_endpoint : UsbHid.HidInterface, Usb.UsbEndpoint -> UsbHid.HidInterface
	hid_add_endpoint = |iface, ep| (if (ep.ep_direction == Usb.usb_ep_dir_in) { { ..{ ..iface, hi_ep_in_addr: ep.ep_address }, hi_ep_in_max: ep.ep_max_packet } } else { { ..{ ..iface, hi_ep_out_addr: ep.ep_address }, hi_ep_out_max: ep.ep_max_packet } })

	hid_classify_device : UsbHid.HidDevice, List(UsbHid.HidInterface) -> UsbHid.HidDevice
	hid_classify_device = |dev_, interfaces| ({
		dev2_ = { ..{ ..dev_, hd_interfaces: interfaces }, hd_interface_count: U64.to_i64_wrap(List.len(interfaces)) }
		hid_classify_loop(dev2_, interfaces, 0, U64.to_i64_wrap(List.len(interfaces)))
	})

	hid_classify_loop : UsbHid.HidDevice, List(UsbHid.HidInterface), I64, I64 -> UsbHid.HidDevice
	hid_classify_loop = |dev_, interfaces, i, n| (if (i >= n) { dev_ } else { ({
		iface = (List.get(interfaces, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		dev2_ = (if (iface.hi_protocol == hid_protocol_keyboard) { { ..dev_, hd_keyboard_if: i } } else { dev_ })
		dev3_ = (if (iface.hi_subclass == hid_subclass_none) { (if (iface.hi_ep_out_addr > 0) { { ..dev2_, hd_raw_if: i } } else { dev2_ }) } else { dev2_ })
		hid_classify_loop(dev3_, interfaces, (i + 1), n)
	}) })

	hid_setup_get_report : I64, I64, I64, I64 -> Usb.UsbSetupPacket
	hid_setup_get_report = |report_type, report_id, interface_num, length| { sp_request_type: 161, sp_request: hid_req_get_report, sp_value: I64.bitwise_or(I64.shl_wrap(report_type, I64.to_u8_wrap(8)), report_id), sp_index: interface_num, sp_length: length }

	hid_setup_set_report : I64, I64, I64, I64 -> Usb.UsbSetupPacket
	hid_setup_set_report = |report_type, report_id, interface_num, length| { sp_request_type: 33, sp_request: hid_req_set_report, sp_value: I64.bitwise_or(I64.shl_wrap(report_type, I64.to_u8_wrap(8)), report_id), sp_index: interface_num, sp_length: length }

	hid_setup_set_idle : I64, I64 -> Usb.UsbSetupPacket
	hid_setup_set_idle = |interface_num, duration| { sp_request_type: 33, sp_request: hid_req_set_idle, sp_value: I64.shl_wrap(duration, I64.to_u8_wrap(8)), sp_index: interface_num, sp_length: 0 }

	hid_setup_set_protocol : I64, I64 -> Usb.UsbSetupPacket
	hid_setup_set_protocol = |interface_num, protocol| { sp_request_type: 33, sp_request: hid_req_set_protocol, sp_value: protocol, sp_index: interface_num, sp_length: 0 }

	hid_setup_get_hid_descriptor : I64, I64 -> Usb.UsbSetupPacket
	hid_setup_get_hid_descriptor = |interface_num, length| { sp_request_type: 129, sp_request: Usb.usb_req_get_descriptor, sp_value: I64.shl_wrap(hid_desc_type_report, I64.to_u8_wrap(8)), sp_index: interface_num, sp_length: length }

	hid_raw_report : I64, List(I64) -> List(I64)
	hid_raw_report = |size, data| hid_pad_report(data, 0, size, [])

	hid_pad_report : List(I64), I64, I64, List(I64) -> List(I64)
	hid_pad_report = |data, i, size, acc| (if (i >= size) { acc } else { ({
		byte = (if (i < U64.to_i64_wrap(List.len(data))) { (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 0 })
		hid_pad_report(data, (i + 1), size, List.append(acc, byte))
	}) })

	hid_has_keyboard : UsbHid.HidDevice -> Bool
	hid_has_keyboard = |dev_| (dev_.hd_keyboard_if >= 0)

	hid_has_raw : UsbHid.HidDevice -> Bool
	hid_has_raw = |dev_| (dev_.hd_raw_if >= 0)

	hid_get_raw_interface : UsbHid.HidDevice -> UsbHid.HidInterface
	hid_get_raw_interface = |dev_| (if (dev_.hd_raw_if < 0) { hid_interface_empty } else { (List.get(dev_.hd_interfaces, I64.to_u64_wrap(dev_.hd_raw_if)) ?? crash("list-at out of range")) })

	hid_get_keyboard_interface : UsbHid.HidDevice -> UsbHid.HidInterface
	hid_get_keyboard_interface = |dev_| (if (dev_.hd_keyboard_if < 0) { hid_interface_empty } else { (List.get(dev_.hd_interfaces, I64.to_u64_wrap(dev_.hd_keyboard_if)) ?? crash("list-at out of range")) })

	format_hid_interface : UsbHid.HidInterface -> List(U8)
	format_hid_interface = |iface| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([17, 28], Text.show_int(iface.hi_number)), [2, 19, 25, 32, 77]), Text.show_int(iface.hi_subclass)), [2, 31, 21, 16, 14, 16, 77]), Text.show_int(iface.hi_protocol)), [2, 13, 31, 73, 17, 18, 77]), Text.show_int(iface.hi_ep_in_addr)), [2, 13, 31, 73, 16, 25, 14, 77]), Text.show_int(iface.hi_ep_out_addr))

	format_hid_device : UsbHid.HidDevice -> List(U8)
	format_hid_device = |dev_| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(Text.show_int(dev_.hd_vendor), [69]), Text.show_int(dev_.hd_product)), [2, 19, 23, 16, 14, 77]), Text.show_int(dev_.hd_slot)), [2, 17, 28, 19, 77]), Text.show_int(dev_.hd_interface_count)), [2, 34, 32, 22, 77]), Text.show_int(dev_.hd_keyboard_if)), [2, 21, 15, 27, 77]), Text.show_int(dev_.hd_raw_if))
}
