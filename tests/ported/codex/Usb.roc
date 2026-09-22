# Usb -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

Usb :: [].{
	UsbDeviceDesc : { usb_vendor : I64, usb_product : I64, usb_class : I64, usb_subclass : I64, usb_protocol : I64, usb_max_packet : I64, usb_num_configs : I64, usb_speed : I64 }
	UsbEndpoint : { ep_address : I64, ep_direction : I64, ep_type : I64, ep_max_packet : I64, ep_interval : I64 }
	UsbInterface : { if_number : I64, if_alt_setting : I64, if_class : I64, if_subclass : I64, if_protocol : I64, if_num_endpoints : I64 }
	UsbSetupPacket : { sp_request_type : I64, sp_request : I64, sp_value : I64, sp_index : I64, sp_length : I64 }

	usb_desc_device : I64
	usb_desc_device = 1

	usb_desc_config : I64
	usb_desc_config = 2

	usb_desc_string : I64
	usb_desc_string = 3

	usb_desc_interface : I64
	usb_desc_interface = 4

	usb_desc_endpoint : I64
	usb_desc_endpoint = 5

	usb_req_get_status : I64
	usb_req_get_status = 0

	usb_req_clear_feature : I64
	usb_req_clear_feature = 1

	usb_req_set_feature : I64
	usb_req_set_feature = 3

	usb_req_set_address : I64
	usb_req_set_address = 5

	usb_req_get_descriptor : I64
	usb_req_get_descriptor = 6

	usb_req_set_config : I64
	usb_req_set_config = 9

	usb_parse_device_desc : List(I64) -> Usb.UsbDeviceDesc
	usb_parse_device_desc = |bytes| (if (U64.to_i64_wrap(List.len(bytes)) < 18) { { usb_vendor: 0, usb_product: 0, usb_class: 0, usb_subclass: 0, usb_protocol: 0, usb_max_packet: 0, usb_num_configs: 0, usb_speed: 0 } } else { { usb_vendor: usb_le16(bytes, 8), usb_product: usb_le16(bytes, 10), usb_class: (List.get(bytes, I64.to_u64_wrap(4)) ?? crash("list-at out of range")), usb_subclass: (List.get(bytes, I64.to_u64_wrap(5)) ?? crash("list-at out of range")), usb_protocol: (List.get(bytes, I64.to_u64_wrap(6)) ?? crash("list-at out of range")), usb_max_packet: (List.get(bytes, I64.to_u64_wrap(7)) ?? crash("list-at out of range")), usb_num_configs: (List.get(bytes, I64.to_u64_wrap(17)) ?? crash("list-at out of range")), usb_speed: 0 } })

	usb_ep_dir_in : I64
	usb_ep_dir_in = 128

	usb_ep_dir_out : I64
	usb_ep_dir_out = 0

	usb_ep_type_control : I64
	usb_ep_type_control = 0

	usb_ep_type_iso : I64
	usb_ep_type_iso = 1

	usb_ep_type_bulk : I64
	usb_ep_type_bulk = 2

	usb_ep_type_interrupt : I64
	usb_ep_type_interrupt = 3

	usb_parse_endpoint : List(I64), I64 -> Usb.UsbEndpoint
	usb_parse_endpoint = |bytes, offset| (if ((offset + 7) > U64.to_i64_wrap(List.len(bytes))) { { ep_address: 0, ep_direction: 0, ep_type: 0, ep_max_packet: 0, ep_interval: 0 } } else { ({
		addr = (List.get(bytes, I64.to_u64_wrap((offset + 2))) ?? crash("list-at out of range"))
		{ ep_address: I64.bitwise_and(addr, 15), ep_direction: I64.bitwise_and(addr, 128), ep_type: I64.bitwise_and((List.get(bytes, I64.to_u64_wrap((offset + 3))) ?? crash("list-at out of range")), 3), ep_max_packet: usb_le16(bytes, (offset + 4)), ep_interval: (List.get(bytes, I64.to_u64_wrap((offset + 6))) ?? crash("list-at out of range")) }
	}) })

	usb_parse_interface : List(I64), I64 -> Usb.UsbInterface
	usb_parse_interface = |bytes, offset| (if ((offset + 8) > U64.to_i64_wrap(List.len(bytes))) { { if_number: 0, if_alt_setting: 0, if_class: 0, if_subclass: 0, if_protocol: 0, if_num_endpoints: 0 } } else { { if_number: (List.get(bytes, I64.to_u64_wrap((offset + 2))) ?? crash("list-at out of range")), if_alt_setting: (List.get(bytes, I64.to_u64_wrap((offset + 3))) ?? crash("list-at out of range")), if_class: (List.get(bytes, I64.to_u64_wrap((offset + 5))) ?? crash("list-at out of range")), if_subclass: (List.get(bytes, I64.to_u64_wrap((offset + 6))) ?? crash("list-at out of range")), if_protocol: (List.get(bytes, I64.to_u64_wrap((offset + 7))) ?? crash("list-at out of range")), if_num_endpoints: (List.get(bytes, I64.to_u64_wrap((offset + 4))) ?? crash("list-at out of range")) } })

	usb_setup_get_descriptor : I64, I64, I64 -> Usb.UsbSetupPacket
	usb_setup_get_descriptor = |desc_type, desc_index, length| { sp_request_type: 128, sp_request: usb_req_get_descriptor, sp_value: I64.bitwise_or(I64.shl_wrap(desc_type, I64.to_u8_wrap(8)), desc_index), sp_index: 0, sp_length: length }

	usb_setup_set_address : I64 -> Usb.UsbSetupPacket
	usb_setup_set_address = |addr| { sp_request_type: 0, sp_request: usb_req_set_address, sp_value: addr, sp_index: 0, sp_length: 0 }

	usb_setup_set_config : I64 -> Usb.UsbSetupPacket
	usb_setup_set_config = |config| { sp_request_type: 0, sp_request: usb_req_set_config, sp_value: config, sp_index: 0, sp_length: 0 }

	usb_feature_endpoint_halt : I64
	usb_feature_endpoint_halt = 0

	usb_setup_clear_halt : I64 -> Usb.UsbSetupPacket
	usb_setup_clear_halt = |endpoint_addr| { sp_request_type: 2, sp_request: usb_req_clear_feature, sp_value: usb_feature_endpoint_halt, sp_index: endpoint_addr, sp_length: 0 }

	usb_encode_setup : Usb.UsbSetupPacket -> List(I64)
	usb_encode_setup = |pkt| List.concat(List.concat(List.concat([pkt.sp_request_type, pkt.sp_request], usb_le16_encode(pkt.sp_value)), usb_le16_encode(pkt.sp_index)), usb_le16_encode(pkt.sp_length))

	usb_class_audio : I64
	usb_class_audio = 1

	usb_subclass_audio_control : I64
	usb_subclass_audio_control = 1

	usb_subclass_audio_streaming : I64
	usb_subclass_audio_streaming = 2

	usb_audio_format_pcm : I64
	usb_audio_format_pcm = 1

	usb_class_hid : I64
	usb_class_hid = 3

	usb_class_mass_storage : I64
	usb_class_mass_storage = 8

	usb_class_hub : I64
	usb_class_hub = 9

	usb_class_video : I64
	usb_class_video = 14

	usb_class_wireless : I64
	usb_class_wireless = 224

	usb_le16 : List(I64), I64 -> I64
	usb_le16 = |bytes, offset| (if ((offset + 2) > U64.to_i64_wrap(List.len(bytes))) { 0 } else { I64.bitwise_or((List.get(bytes, I64.to_u64_wrap(offset)) ?? crash("list-at out of range")), I64.shl_wrap((List.get(bytes, I64.to_u64_wrap((offset + 1))) ?? crash("list-at out of range")), I64.to_u8_wrap(8))) })

	usb_le16_encode : I64 -> List(I64)
	usb_le16_encode = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255)]

	format_usb_device : Usb.UsbDeviceDesc -> List(U8)
	format_usb_device = |d| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(usb_hex16(d.usb_vendor), [69]), usb_hex16(d.usb_product)), [2, 24, 23, 15, 19, 19, 77]), Text.show_int(d.usb_class)), [65]), Text.show_int(d.usb_subclass))

	format_usb_endpoint : Usb.UsbEndpoint -> List(U8)
	format_usb_endpoint = |ep| ({
		dir = (if (ep.ep_direction == 128) { [43, 44] } else { [42, 51, 40] })
		typ = (if (ep.ep_type == 0) { [50, 40, 47, 49] } else { (if (ep.ep_type == 1) { [43, 45, 42] } else { (if (ep.ep_type == 2) { [58, 51, 49, 60] } else { [43, 44, 40] }) }) })
		List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([39, 57], Text.show_int(ep.ep_address)), [2]), dir), [2]), typ), [2, 26, 15, 36, 31, 34, 14, 77]), Text.show_int(ep.ep_max_packet))
	})

	usb_hex16 : I64 -> List(U8)
	usb_hex16 = |v| List.concat(List.concat(List.concat(usb_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(12)), 15)), usb_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 15))), usb_nib(I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(4)), 15))), usb_nib(I64.bitwise_and(v, 15)))

	usb_nib : I64 -> List(U8)
	usb_nib = |n| (if (n == 0) { [3] } else { (if (n == 1) { [4] } else { (if (n == 2) { [5] } else { (if (n == 3) { [6] } else { (if (n == 4) { [7] } else { (if (n == 5) { [8] } else { (if (n == 6) { [9] } else { (if (n == 7) { [10] } else { (if (n == 8) { [11] } else { (if (n == 9) { [12] } else { (if (n == 10) { [15] } else { (if (n == 11) { [32] } else { (if (n == 12) { [24] } else { (if (n == 13) { [22] } else { (if (n == 14) { [13] } else { [28] }) }) }) }) }) }) }) }) }) }) }) }) }) }) })
}
