# bacnet-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bacnet-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     8

app [main!] { cdx: "./codex/main.roc" }

import cdx.Bacnet

# BacnetEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_read_property : I64
check_read_property = flag(bytes_eq(Bacnet.bacnet_build_read_property(1, Bacnet.bacnet_obj_analog_input, 1, Bacnet.bacnet_prop_present_value), [129, 10, 0, 17, 1, 4, 0, 5, 1, 12, 12, 0, 0, 0, 1, 25, 85]))

check_object_id : I64
check_object_id = flag(bytes_eq(Bacnet.bacnet_context_object_id(0, Bacnet.bacnet_obj_device, 260), [12, 2, 0, 1, 4]))

check_unsigned_1byte : I64
check_unsigned_1byte = flag(bytes_eq(Bacnet.bacnet_context_unsigned(1, 85), [25, 85]))

check_unsigned_2byte : I64
check_unsigned_2byte = flag(bytes_eq(Bacnet.bacnet_context_unsigned(1, 512), [26, 2, 0]))

check_app_unsigned : I64
check_app_unsigned = flag(bytes_eq(Bacnet.bacnet_app_unsigned(42), [33, 42]))

check_app_real : I64
check_app_real = flag(bytes_eq(Bacnet.bacnet_app_real(F64.to_f32_wrap(42.5)), [68, 66, 42, 0, 0]))

check_write_property : I64
check_write_property = flag(bytes_eq(Bacnet.bacnet_write_property_apdu(1, Bacnet.bacnet_obj_analog_value, 1, Bacnet.bacnet_prop_present_value, Bacnet.bacnet_app_unsigned(42)), [0, 5, 1, 15, 12, 0, 128, 0, 1, 25, 85, 62, 33, 42, 63]))

check_build_write : I64
check_build_write = flag(bytes_eq(Bacnet.bacnet_build_write_property(1, Bacnet.bacnet_obj_analog_value, 1, Bacnet.bacnet_prop_present_value, Bacnet.bacnet_app_unsigned(42)), [129, 10, 0, 21, 1, 4, 0, 5, 1, 15, 12, 0, 128, 0, 1, 25, 85, 62, 33, 42, 63]))

# --- Entry ---

main! = |_args| {
	a = check_read_property
	b = check_object_id
	c = check_unsigned_1byte
	d = check_unsigned_2byte
	e = check_app_unsigned
	f = check_app_real
	g = check_write_property
	h = check_build_write
	line!(I64.to_str((((((((a + b) + c) + d) + e) + f) + g) + h)))
	Ok({})
}
