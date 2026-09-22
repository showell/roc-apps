# Enip -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Enip :: [].{

	enip_u16_le : I64 -> List(I64)
	enip_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255)]

	enip_u32_le : I64 -> List(I64)
	enip_u32_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255)]

	enip_context_zero : List(I64)
	enip_context_zero = [0, 0, 0, 0, 0, 0, 0, 0]

	enip_cmd_nop : I64
	enip_cmd_nop = 0

	enip_cmd_list_services : I64
	enip_cmd_list_services = 4

	enip_cmd_list_identity : I64
	enip_cmd_list_identity = 99

	enip_cmd_list_interfaces : I64
	enip_cmd_list_interfaces = 100

	enip_cmd_register_session : I64
	enip_cmd_register_session = 101

	enip_cmd_unregister_session : I64
	enip_cmd_unregister_session = 102

	enip_cmd_send_rr_data : I64
	enip_cmd_send_rr_data = 111

	enip_cmd_send_unit_data : I64
	enip_cmd_send_unit_data = 112

	enip_header : I64, I64, I64, I64, I64 -> List(I64)
	enip_header = |command, length, session, status, options| List.concat(List.concat(List.concat(List.concat(List.concat(enip_u16_le(command), enip_u16_le(length)), enip_u32_le(session)), enip_u32_le(status)), enip_context_zero), enip_u32_le(options))

	enip_frame : I64, I64, I64, I64, List(I64) -> List(I64)
	enip_frame = |command, session, status, options, data| List.concat(enip_header(command, U64.to_i64_wrap(List.len(data)), session, status, options), data)

	enip_register_session : List(I64)
	enip_register_session = enip_frame(enip_cmd_register_session, 0, 0, 0, List.concat(enip_u16_le(1), enip_u16_le(0)))

	cip_svc_get_attr_all : I64
	cip_svc_get_attr_all = 1

	cip_svc_get_attr_single : I64
	cip_svc_get_attr_single = 14

	cip_svc_set_attr_single : I64
	cip_svc_set_attr_single = 16

	cip_epath_class_instance_attr : I64, I64, I64 -> List(I64)
	cip_epath_class_instance_attr = |cls, inst, attr| [32, cls, 36, inst, 48, attr]

	cip_request : I64, List(I64) -> List(I64)
	cip_request = |service, path| List.concat([service, I64.div_trunc_by(U64.to_i64_wrap(List.len(path)), 2)], path)

	cip_get_attr_single : I64, I64, I64 -> List(I64)
	cip_get_attr_single = |cls, inst, attr| cip_request(cip_svc_get_attr_single, cip_epath_class_instance_attr(cls, inst, attr))

	enip_cpf_unconnected : List(I64) -> List(I64)
	enip_cpf_unconnected = |cip| List.concat(List.concat(List.concat(List.concat(List.concat(enip_u16_le(2), enip_u16_le(0)), enip_u16_le(0)), enip_u16_le(178)), enip_u16_le(U64.to_i64_wrap(List.len(cip)))), cip)

	enip_send_rr_data : I64, I64, List(I64) -> List(I64)
	enip_send_rr_data = |session, timeout, cip| enip_frame(enip_cmd_send_rr_data, session, 0, 0, List.concat(List.concat(enip_u32_le(0), enip_u16_le(timeout)), enip_cpf_unconnected(cip)))
}
