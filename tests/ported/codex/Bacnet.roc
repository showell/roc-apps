# Bacnet -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Bacnet :: [].{

	bacnet_obj_analog_input : I64
	bacnet_obj_analog_input = 0

	bacnet_obj_analog_output : I64
	bacnet_obj_analog_output = 1

	bacnet_obj_analog_value : I64
	bacnet_obj_analog_value = 2

	bacnet_obj_binary_input : I64
	bacnet_obj_binary_input = 3

	bacnet_obj_binary_output : I64
	bacnet_obj_binary_output = 4

	bacnet_obj_binary_value : I64
	bacnet_obj_binary_value = 5

	bacnet_obj_device : I64
	bacnet_obj_device = 8

	bacnet_obj_multi_state_value : I64
	bacnet_obj_multi_state_value = 19

	bacnet_prop_description : I64
	bacnet_prop_description = 28

	bacnet_prop_object_name : I64
	bacnet_prop_object_name = 77

	bacnet_prop_object_type : I64
	bacnet_prop_object_type = 79

	bacnet_prop_present_value : I64
	bacnet_prop_present_value = 85

	bacnet_prop_status_flags : I64
	bacnet_prop_status_flags = 111

	bacnet_prop_units : I64
	bacnet_prop_units = 117

	bacnet_svc_read_property : I64
	bacnet_svc_read_property = 12

	bacnet_svc_read_property_multiple : I64
	bacnet_svc_read_property_multiple = 14

	bacnet_svc_write_property : I64
	bacnet_svc_write_property = 15

	bacnet_bvlc_original_unicast : I64
	bacnet_bvlc_original_unicast = 10

	bacnet_bvlc_original_broadcast : I64
	bacnet_bvlc_original_broadcast = 11

	bacnet_object_id_bytes : I64, I64 -> List(I64)
	bacnet_object_id_bytes = |obj_type, inst| ({
		v : I64
		v = I64.bitwise_or(I64.shl_wrap(obj_type, I64.to_u8_wrap(22)), inst)
		[I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]
	})

	bacnet_context_object_id : I64, I64, I64 -> List(I64)
	bacnet_context_object_id = |tag_num, obj_type, inst| List.concat([I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(tag_num, I64.to_u8_wrap(4)), 8), 4)], bacnet_object_id_bytes(obj_type, inst))

	bacnet_context_unsigned : I64, I64 -> List(I64)
	bacnet_context_unsigned = |tag_num, v| ({
		content : List(I64)
		content = (if (v < 256) { [v] } else { [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)] })
		List.concat([I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(tag_num, I64.to_u8_wrap(4)), 8), U64.to_i64_wrap(List.len(content)))], content)
	})

	bacnet_npdu : I64 -> List(I64)
	bacnet_npdu = |control| [1, control]

	bacnet_bvlc : I64, List(I64) -> List(I64)
	bacnet_bvlc = |function, payload| ({
		total : I64
		total = (4 + U64.to_i64_wrap(List.len(payload)))
		List.concat([129, function, I64.bitwise_and(I64.shr_zf_wrap(total, I64.to_u8_wrap(8)), 255), I64.bitwise_and(total, 255)], payload)
	})

	bacnet_read_property_apdu : I64, I64, I64, I64 -> List(I64)
	bacnet_read_property_apdu = |invoke_id, obj_type, inst, prop_id| List.concat(List.concat([0, 5, invoke_id, bacnet_svc_read_property], bacnet_context_object_id(0, obj_type, inst)), bacnet_context_unsigned(1, prop_id))

	bacnet_build_read_property : I64, I64, I64, I64 -> List(I64)
	bacnet_build_read_property = |invoke_id, obj_type, inst, prop_id| bacnet_bvlc(bacnet_bvlc_original_unicast, List.concat(bacnet_npdu(4), bacnet_read_property_apdu(invoke_id, obj_type, inst, prop_id)))

	bacnet_u32_be : I64 -> List(I64)
	bacnet_u32_be = |v| [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	bacnet_app_unsigned : I64 -> List(I64)
	bacnet_app_unsigned = |v| (if (v < 256) { [I64.bitwise_or(I64.shl_wrap(2, I64.to_u8_wrap(4)), 1), v] } else { [I64.bitwise_or(I64.shl_wrap(2, I64.to_u8_wrap(4)), 2), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)] })

	bacnet_app_enumerated : I64 -> List(I64)
	bacnet_app_enumerated = |v| [I64.bitwise_or(I64.shl_wrap(9, I64.to_u8_wrap(4)), 1), v]

	bacnet_app_real : F32 -> List(I64)
	bacnet_app_real = |r| List.concat([I64.bitwise_or(I64.shl_wrap(4, I64.to_u8_wrap(4)), 4)], bacnet_u32_be(U32.to_i64(F32.to_bits(r))))

	bacnet_open_tag : I64 -> I64
	bacnet_open_tag = |tag_num| I64.bitwise_or(I64.shl_wrap(tag_num, I64.to_u8_wrap(4)), 14)

	bacnet_close_tag : I64 -> I64
	bacnet_close_tag = |tag_num| I64.bitwise_or(I64.shl_wrap(tag_num, I64.to_u8_wrap(4)), 15)

	bacnet_write_property_apdu : I64, I64, I64, I64, List(I64) -> List(I64)
	bacnet_write_property_apdu = |invoke_id, obj_type, inst, prop_id, value| List.concat(List.concat(List.concat(List.concat(List.concat([0, 5, invoke_id, bacnet_svc_write_property], bacnet_context_object_id(0, obj_type, inst)), bacnet_context_unsigned(1, prop_id)), [bacnet_open_tag(3)]), value), [bacnet_close_tag(3)])

	bacnet_build_write_property : I64, I64, I64, I64, List(I64) -> List(I64)
	bacnet_build_write_property = |invoke_id, obj_type, inst, prop_id, value| bacnet_bvlc(bacnet_bvlc_original_unicast, List.concat(bacnet_npdu(4), bacnet_write_property_apdu(invoke_id, obj_type, inst, prop_id, value)))
}
