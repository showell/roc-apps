# BleAtt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

BleAtt :: [].{

	att_op_error : I64
	att_op_error = 1

	att_op_exchange_mtu_request : I64
	att_op_exchange_mtu_request = 2

	att_op_read_request : I64
	att_op_read_request = 10

	att_op_read_response : I64
	att_op_read_response = 11

	att_op_write_request : I64
	att_op_write_request = 18

	att_op_write_response : I64
	att_op_write_response = 19

	att_op_notification : I64
	att_op_notification = 27

	att_op_indication : I64
	att_op_indication = 29

	att_op_write_command : I64
	att_op_write_command = 82

	l2cap_cid_att : I64
	l2cap_cid_att = 4

	att_u16_le : I64 -> List(I64)
	att_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255)]

	att_exchange_mtu_request : I64 -> List(I64)
	att_exchange_mtu_request = |mtu| List.concat([att_op_exchange_mtu_request], att_u16_le(mtu))

	att_read_request : I64 -> List(I64)
	att_read_request = |handle| List.concat([att_op_read_request], att_u16_le(handle))

	att_write_request : I64, List(I64) -> List(I64)
	att_write_request = |handle, value| List.concat(List.concat([att_op_write_request], att_u16_le(handle)), value)

	att_write_command : I64, List(I64) -> List(I64)
	att_write_command = |handle, value| List.concat(List.concat([att_op_write_command], att_u16_le(handle)), value)

	att_read_response : List(I64) -> List(I64)
	att_read_response = |value| List.concat([att_op_read_response], value)

	att_notification : I64, List(I64) -> List(I64)
	att_notification = |handle, value| List.concat(List.concat([att_op_notification], att_u16_le(handle)), value)

	att_indication : I64, List(I64) -> List(I64)
	att_indication = |handle, value| List.concat(List.concat([att_op_indication], att_u16_le(handle)), value)

	att_error_response : I64, I64, I64 -> List(I64)
	att_error_response = |request_op, handle, error_code| List.concat(List.concat([att_op_error, request_op], att_u16_le(handle)), [error_code])

	l2cap_frame : I64, List(I64) -> List(I64)
	l2cap_frame = |cid, payload| List.concat(List.concat(att_u16_le(U64.to_i64_wrap(List.len(payload))), att_u16_le(cid)), payload)

	att_l2cap : List(I64) -> List(I64)
	att_l2cap = |pdu| l2cap_frame(l2cap_cid_att, pdu)
}
