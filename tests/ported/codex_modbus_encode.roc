# modbus-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/modbus-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     17

app [main!] { cdx: "./codex/main.roc" }

import cdx.Modbus

# ModbusEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_read_holding : I64
check_read_holding = flag(bytes_eq(Modbus.modbus_read_holding_registers(0, 1), [3, 0, 0, 0, 1]))

check_crc_known : I64
check_crc_known = flag((Modbus.modbus_crc16([1, 3, 0, 0, 0, 1]) == 2692))

check_rtu_frame : I64
check_rtu_frame = flag(bytes_eq(Modbus.modbus_rtu_frame(1, Modbus.modbus_read_holding_registers(0, 1)), [1, 3, 0, 0, 0, 1, 132, 10]))

check_rtu_selfcheck : I64
check_rtu_selfcheck = flag(Modbus.modbus_rtu_check(Modbus.modbus_rtu_frame(1, Modbus.modbus_read_holding_registers(0, 1))))

check_tcp_frame : I64
check_tcp_frame = flag(bytes_eq(Modbus.modbus_tcp_frame(1, 1, Modbus.modbus_read_holding_registers(0, 1)), [0, 1, 0, 0, 0, 6, 1, 3, 0, 0, 0, 1]))

check_write_register : I64
check_write_register = flag(bytes_eq(Modbus.modbus_write_single_register(1, 4660), [6, 0, 1, 18, 52]))

check_write_coil : I64
check_write_coil = flag(bytes_eq(Modbus.modbus_write_single_coil(5, True), [5, 0, 5, 255, 0]))

check_write_multiple : I64
check_write_multiple = flag(bytes_eq(Modbus.modbus_write_multiple_registers(0, [10, 258]), [16, 0, 0, 0, 2, 4, 0, 10, 1, 2]))

check_parse_registers : I64
check_parse_registers = flag(bytes_eq(Modbus.modbus_parse_registers([3, 2, 0, 42]), [42]))

check_exception : I64
check_exception = flag((if Modbus.modbus_is_exception([131, 2]) { (Modbus.modbus_exception_code([131, 2]) == 2) } else { False }))

check_write_coils : I64
check_write_coils = flag(bytes_eq(Modbus.modbus_write_multiple_coils(19, [True, False, True, True, False, False, True, True, True, False]), [15, 0, 19, 0, 10, 2, 205, 1]))

check_parse_coils : I64
check_parse_coils = flag(bytes_eq(Modbus.modbus_write_multiple_coils(0, Modbus.modbus_parse_coils([1, 2, 205, 1], 10)), [15, 0, 0, 0, 10, 2, 205, 1]))

check_lrc : I64
check_lrc = flag((Modbus.modbus_lrc([1, 3, 0, 0, 0, 1]) == 251))

check_ascii_frame : I64
check_ascii_frame = flag(bytes_eq(Modbus.modbus_ascii_frame(1, Modbus.modbus_read_holding_registers(0, 1)), [58, 48, 49, 48, 51, 48, 48, 48, 48, 48, 48, 48, 49, 70, 66, 13, 10]))

check_exception_status : I64
check_exception_status = flag(bytes_eq(Modbus.modbus_read_exception_status, [7]))

check_mask_write : I64
check_mask_write = flag(bytes_eq(Modbus.modbus_mask_write_register(4, 242, 37), [22, 0, 4, 0, 242, 0, 37]))

check_read_write_multiple : I64
check_read_write_multiple = flag(bytes_eq(Modbus.modbus_read_write_multiple_registers(3, 6, 14, [255, 255, 255]), [23, 0, 3, 0, 6, 0, 14, 0, 3, 6, 0, 255, 0, 255, 0, 255]))

# --- Entry ---

main! = |_args| {
	a = check_read_holding
	b = check_crc_known
	c = check_rtu_frame
	d = check_rtu_selfcheck
	e = check_tcp_frame
	f = check_write_register
	g = check_write_coil
	h = check_write_multiple
	i = check_parse_registers
	j = check_exception
	k = check_write_coils
	l = check_parse_coils
	m = check_lrc
	n = check_ascii_frame
	o = check_exception_status
	p = check_mask_write
	q = check_read_write_multiple
	line!(I64.to_str(((((((((((((((((a + b) + c) + d) + e) + f) + g) + h) + i) + j) + k) + l) + m) + n) + o) + p) + q)))
	Ok({})
}
