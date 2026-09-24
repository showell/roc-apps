# capability-doors
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/capability-doors.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     agree=75/75
#     granting=75/75
#     union=25/25 refines=25/25
#     unknown-id=-1 unknown-name-bits=0 unknown-id-bits=0
#     names=31 rows=25 resolving=25
#     console=17,33,49
#     filesystem=64,128,192
#     concurrent=6152,6152

app [main!] { cdx: "./codex/main.roc" }

import cdx.Capability
import cdx.CceText

# CapabilityDoors -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

doors_agree : List(Capability.CapSpec), I64, I64, I64, I64 -> I64
doors_agree = |ts, i, len, dir, acc| (if (i >= len) { acc } else { ({
	s = (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	by_name = Capability.cap_bits_for_name(s.cs_name, dir)
	by_id = Capability.cap_bits_for_id(Capability.cap_id_for_name(s.cs_name), dir)
	doors_agree(ts, (i + 1), len, dir, (acc + (if (by_name == by_id) { 1 } else { 0 })))
}) })

doors_nonzero : List(Capability.CapSpec), I64, I64, I64, I64 -> I64
doors_nonzero = |ts, i, len, dir, acc| (if (i >= len) { acc } else { ({
	s = (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	by_name = Capability.cap_bits_for_name(s.cs_name, dir)
	doors_nonzero(ts, (i + 1), len, dir, (acc + (if (by_name != 0) { 1 } else { 0 })))
}) })

test_doors : CceText
test_doors = ({
	ts = Capability.capability_table
	n = U64.to_i64_wrap(List.len(ts))
	ar = doors_agree(ts, 0, n, Capability.cap_dir_read, 0)
	aw = doors_agree(ts, 0, n, Capability.cap_dir_write, 0)
	arw = doors_agree(ts, 0, n, Capability.cap_dir_readwrite, 0)
	CceText.concat(CceText.concat(CceText.concat("agree=", CceText.show_int(((ar + aw) + arw))), "/"), CceText.show_int((n * 3)))
})

test_nonzero : CceText
test_nonzero = ({
	ts = Capability.capability_table
	n = U64.to_i64_wrap(List.len(ts))
	zr = doors_nonzero(ts, 0, n, Capability.cap_dir_read, 0)
	zw = doors_nonzero(ts, 0, n, Capability.cap_dir_write, 0)
	zrw = doors_nonzero(ts, 0, n, Capability.cap_dir_readwrite, 0)
	CceText.concat(CceText.concat(CceText.concat("granting=", CceText.show_int(((zr + zw) + zrw))), "/"), CceText.show_int((n * 3)))
})

dir_union_ok : List(Capability.CapSpec), I64, I64, I64 -> I64
dir_union_ok = |ts, i, len, acc| (if (i >= len) { acc } else { ({
	s = (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	r = Capability.cap_bits_for_name(s.cs_name, Capability.cap_dir_read)
	w = Capability.cap_bits_for_name(s.cs_name, Capability.cap_dir_write)
	rw = Capability.cap_bits_for_name(s.cs_name, Capability.cap_dir_readwrite)
	dir_union_ok(ts, (i + 1), len, (acc + (if (I64.bitwise_or(r, w) == rw) { 1 } else { 0 })))
}) })

cd_both : Bool, Bool -> Bool
cd_both = |a, b| (if a { b } else { False })

dir_distinct_ok : List(Capability.CapSpec), I64, I64, I64 -> I64
dir_distinct_ok = |ts, i, len, acc| (if (i >= len) { acc } else { ({
	s = (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	r = Capability.cap_bits_for_name(s.cs_name, Capability.cap_dir_read)
	w = Capability.cap_bits_for_name(s.cs_name, Capability.cap_dir_write)
	rw = Capability.cap_bits_for_name(s.cs_name, Capability.cap_dir_readwrite)
	directional = (s.cs_read_bit >= 0)
	ok = (if directional { cd_both((r != rw), (w != rw)) } else { cd_both((r == rw), (w == rw)) })
	dir_distinct_ok(ts, (i + 1), len, (acc + (if ok { 1 } else { 0 })))
}) })

test_directions : CceText
test_directions = ({
	ts = Capability.capability_table
	n = U64.to_i64_wrap(List.len(ts))
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("union=", CceText.show_int(dir_union_ok(ts, 0, n, 0))), "/"), CceText.show_int(n)), " refines="), CceText.show_int(dir_distinct_ok(ts, 0, n, 0))), "/"), CceText.show_int(n))
})

test_ungranted : CceText
test_ungranted = ({
	bad_id = Capability.cap_id_for_name("NotACapability")
	r = Capability.cap_bits_for_name("NotACapability", Capability.cap_dir_read)
	w = Capability.cap_bits_for_name("NotACapability", Capability.cap_dir_write)
	rw = Capability.cap_bits_for_name("NotACapability", Capability.cap_dir_readwrite)
	by_id = Capability.cap_bits_for_id(999, Capability.cap_dir_readwrite)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("unknown-id=", CceText.show_int(bad_id)), " unknown-name-bits="), CceText.show_int(((r + w) + rw))), " unknown-id-bits="), CceText.show_int(by_id))
})

vocab_resolving : List(CceText), I64, I64, I64 -> I64
vocab_resolving = |ns, i, len, acc| (if (i >= len) { acc } else { vocab_resolving(ns, (i + 1), len, (acc + (if (Capability.cap_id_for_name((List.get(ns, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) >= 0) { 1 } else { 0 }))) })

test_vocab : CceText
test_vocab = ({
	ns = Capability.capability_names
	n = U64.to_i64_wrap(List.len(ns))
	rows = U64.to_i64_wrap(List.len(Capability.capability_table))
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("names=", CceText.show_int(n)), " rows="), CceText.show_int(rows)), " resolving="), CceText.show_int(vocab_resolving(ns, 0, n, 0)))
})

test_masks : CceText
test_masks = ({
	cr = Capability.cap_bits_for_name("Console", Capability.cap_dir_read)
	cw = Capability.cap_bits_for_name("Console", Capability.cap_dir_write)
	crw = Capability.cap_bits_for_name("Console", Capability.cap_dir_readwrite)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("console=", CceText.show_int(cr)), ","), CceText.show_int(cw)), ","), CceText.show_int(crw))
})

test_masks_fs : CceText
test_masks_fs = ({
	fr = Capability.cap_bits_for_name("FileSystem", Capability.cap_dir_read)
	fw = Capability.cap_bits_for_name("FileSystem", Capability.cap_dir_write)
	frw = Capability.cap_bits_for_name("FileSystem", Capability.cap_dir_readwrite)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("filesystem=", CceText.show_int(fr)), ","), CceText.show_int(fw)), ","), CceText.show_int(frw))
})

test_masks_conc : CceText
test_masks_conc = ({
	kr = Capability.cap_bits_for_name("Concurrent", Capability.cap_dir_read)
	krw = Capability.cap_bits_for_name("Concurrent", Capability.cap_dir_readwrite)
	CceText.concat(CceText.concat(CceText.concat("concurrent=", CceText.show_int(kr)), ","), CceText.show_int(krw))
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_doors))
	line!(CceText.printed(test_nonzero))
	line!(CceText.printed(test_directions))
	line!(CceText.printed(test_ungranted))
	line!(CceText.printed(test_vocab))
	line!(CceText.printed(test_masks))
	line!(CceText.printed(test_masks_fs))
	line!(CceText.printed(test_masks_conc))
	Ok({})
}
