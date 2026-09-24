# sntp-encode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/sntp-encode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5

app [main!] { cdx: "./codex/main.roc" }

import cdx.Sntp

# SntpEncodeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_eq : List(I64), List(I64) -> Bool
bytes_eq = |a, b| (if (U64.to_i64_wrap(List.len(a)) != U64.to_i64_wrap(List.len(b))) { False } else { bytes_eq_loop(a, b, 0, U64.to_i64_wrap(List.len(a))) })

bytes_eq_loop : List(I64), List(I64), I64, I64 -> Bool
bytes_eq_loop = |a, b, i, len| (if (i >= len) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { bytes_eq_loop(a, b, (i + 1), len) }) })

flag : Bool -> I64
flag = |b| (if b { 1 } else { 0 })

check_length_flag : I64
check_length_flag = ({
	req : List(I64)
	req = Sntp.sntp_build_request(3789743076)
	flag((if (U64.to_i64_wrap(List.len(req)) == 48) { ((List.get(req, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) == 35) } else { False }))
})

check_transmit_field : I64
check_transmit_field = ({
	req : List(I64)
	req = Sntp.sntp_build_request(3789743076)
	flag(bytes_eq([(List.get(req, I64.to_u64_wrap(40)) ?? crash("list-at out of range")), (List.get(req, I64.to_u64_wrap(41)) ?? crash("list-at out of range")), (List.get(req, I64.to_u64_wrap(42)) ?? crash("list-at out of range")), (List.get(req, I64.to_u64_wrap(43)) ?? crash("list-at out of range"))], [225, 226, 227, 228]))
})

check_roundtrip : I64
check_roundtrip = flag((Sntp.sntp_transmit_seconds(Sntp.sntp_build_request(3789743076)) == 3789743076))

check_mode_version : I64
check_mode_version = ({
	req : List(I64)
	req = Sntp.sntp_build_request(0)
	flag((if (Sntp.sntp_mode(req) == 3) { (Sntp.sntp_version(req) == 4) } else { False }))
})

check_epoch : I64
check_epoch = flag((if (Sntp.sntp_ntp_to_unix(2208988800) == 0) { (Sntp.sntp_unix_to_ntp(0) == 2208988800) } else { False }))

# --- Entry ---

main! = |_args| {
	a = check_length_flag
	b = check_transmit_field
	c = check_roundtrip
	d = check_mode_version
	e = check_epoch
	line!(I64.to_str(((((a + b) + c) + d) + e)))
	Ok({})
}
