# Zigbee -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Zigbee :: [].{

	zb_nwk_type_data : I64
	zb_nwk_type_data = 0

	zb_nwk_type_command : I64
	zb_nwk_type_command = 1

	zb_nwk_version : I64
	zb_nwk_version = 2

	zb_nwk_fc : I64, I64, I64, I64 -> I64
	zb_nwk_fc = |ftype, version, discover, security| I64.bitwise_or(I64.bitwise_or(ftype, I64.shl_wrap(version, I64.to_u8_wrap(2))), I64.bitwise_or(I64.shl_wrap(discover, I64.to_u8_wrap(6)), I64.shl_wrap(security, I64.to_u8_wrap(9))))

	zb_aps_type_data : I64
	zb_aps_type_data = 0

	zb_aps_type_command : I64
	zb_aps_type_command = 1

	zb_aps_fc : I64, I64, I64, I64 -> I64
	zb_aps_fc = |ftype, delivery, ackreq, security| I64.bitwise_or(I64.bitwise_or(ftype, I64.shl_wrap(delivery, I64.to_u8_wrap(2))), I64.bitwise_or(I64.shl_wrap(security, I64.to_u8_wrap(5)), I64.shl_wrap(ackreq, I64.to_u8_wrap(6))))

	zb_u16_le : I64 -> List(I64)
	zb_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255)]

	zb_build_nwk_data : I64, I64, I64, I64, List(I64) -> List(I64)
	zb_build_nwk_data = |dest, src, radius, seq, payload| List.concat(List.concat(List.concat(List.concat(zb_u16_le(zb_nwk_fc(zb_nwk_type_data, zb_nwk_version, 0, 0)), zb_u16_le(dest)), zb_u16_le(src)), [radius, seq]), payload)

	zb_build_aps_data : I64, I64, I64, I64, I64, List(I64) -> List(I64)
	zb_build_aps_data = |dest_ep, cluster, profile, src_ep, counter, payload| List.concat(List.concat(List.concat(List.concat([zb_aps_fc(zb_aps_type_data, 0, 0, 0), dest_ep], zb_u16_le(cluster)), zb_u16_le(profile)), [src_ep, counter]), payload)
}
