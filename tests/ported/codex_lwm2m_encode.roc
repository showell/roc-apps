# lwm2m-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lwm2m-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     12

app [main!] { cdx: "./codex/main.roc" }

import cdx.Lwm2m
import cdx.Text

# Lwm2mEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_device_obj : I64
test_device_obj = (if (Lwm2m.lwm2m_obj_device == 3) { 1 } else { 0 })

test_firmware_obj : I64
test_firmware_obj = (if (Lwm2m.lwm2m_obj_firmware == 5) { 1 } else { 0 })

test_uri : I64
test_uri = ({
	u = Lwm2m.lwm2m_uri(3, 0, 1)
	(if (Text.len(u) > 0) { 1 } else { 0 })
})

test_object_uri : I64
test_object_uri = ({
	u = Lwm2m.lwm2m_object_uri(3, 0)
	(if (Text.len(u) > 0) { 1 } else { 0 })
})

test_tlv_encode : I64
test_tlv_encode = ({
	encoded = Lwm2m.lwm2m_encode_tlv_resource(1, [65, 66, 67])
	(if (U64.to_i64_wrap(List.len(encoded)) > 0) { 1 } else { 0 })
})

tlv_matches : List(I64), List(I64), I64, I64 -> I64
tlv_matches = |a, b, i, n| (if (U64.to_i64_wrap(List.len(a)) != n) { 0 } else { (if (i >= n) { 1 } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { 0 } else { tlv_matches(a, b, (i + 1), n) }) }) })

test_tlv_short : I64
test_tlv_short = ({
	e = Lwm2m.lwm2m_encode_tlv_resource(1, [65, 66, 67])
	tlv_matches(e, [195, 1, 65, 66, 67], 0, 5)
})

test_tlv_long_id : I64
test_tlv_long_id = ({
	e = Lwm2m.lwm2m_encode_tlv_resource(3303, [7])
	tlv_matches(e, [225, 12, 231, 7], 0, 4)
})

test_tlv_long_value : I64
test_tlv_long_value = ({
	e = Lwm2m.lwm2m_encode_tlv_resource(1, [0, 1, 2, 3, 4, 5, 6, 7])
	tlv_matches(e, [200, 1, 8, 0, 1, 2, 3, 4, 5, 6, 7], 0, 11)
})

test_registration_fields : I64
test_registration_fields = ({
	reg = Lwm2m.default_lwm2m_registration
	ok_endpoint = (if (reg.endpoint == "codex-device") { 1 } else { 0 })
	ok_lifetime = (if (reg.lifetime == 300) { 1 } else { 0 })
	ok_binding = (if (reg.binding == "U") { 1 } else { 0 })
	((ok_endpoint + ok_lifetime) + ok_binding)
})

test_registration_path : I64
test_registration_path = ({
	path = Lwm2m.lwm2m_registration_path(Lwm2m.default_lwm2m_registration)
	(if (Text.len(path) > 0) { 1 } else { 0 })
})

# --- Entry ---

main! = |_args| {
	d = test_device_obj
	f = test_firmware_obj
	u = test_uri
	ou = test_object_uri
	t = test_tlv_encode
	rf = test_registration_fields
	rp = test_registration_path
	s = test_tlv_short
	li = test_tlv_long_id
	lv = test_tlv_long_value
	line!(I64.to_str((((((((((d + f) + u) + ou) + t) + rf) + rp) + s) + li) + lv)))
	Ok({})
}
