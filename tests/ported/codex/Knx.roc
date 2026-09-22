# Knx -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Knx :: [].{

	knx_group_address : I64, I64, I64 -> I64
	knx_group_address = |main, middle, sub| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(main, I64.to_u8_wrap(11)), I64.shl_wrap(middle, I64.to_u8_wrap(8))), sub)

	knx_individual_address : I64, I64, I64 -> I64
	knx_individual_address = |area, line, device| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(area, I64.to_u8_wrap(12)), I64.shl_wrap(line, I64.to_u8_wrap(8))), device)

	knx_mc_l_data_req : I64
	knx_mc_l_data_req = 17

	knx_mc_l_data_ind : I64
	knx_mc_l_data_ind = 41

	knx_service_routing_indication : I64
	knx_service_routing_indication = 1328

	knx_service_tunnelling_request : I64
	knx_service_tunnelling_request = 1056

	knx_apci_group_write : I64
	knx_apci_group_write = 128

	knx_u16_be : I64 -> List(I64)
	knx_u16_be = |v| [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	knx_cemi_group_write : I64, I64, I64 -> List(I64)
	knx_cemi_group_write = |src, dst, value6| List.concat(List.concat(List.concat([knx_mc_l_data_req, 0, 188, 224], knx_u16_be(src)), knx_u16_be(dst)), [1, 0, I64.bitwise_or(knx_apci_group_write, value6)])

	knx_frame : I64, List(I64) -> List(I64)
	knx_frame = |service, body| List.concat(List.concat(List.concat([6, 16], knx_u16_be(service)), knx_u16_be((6 + U64.to_i64_wrap(List.len(body))))), body)

	knx_routing_group_write : I64, I64, I64 -> List(I64)
	knx_routing_group_write = |src, dst, value6| knx_frame(knx_service_routing_indication, knx_cemi_group_write(src, dst, value6))
}
