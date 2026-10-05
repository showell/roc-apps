app [main!] { pf: platform "../../../../../showell_repos/roc-apps/machine/batch/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# Fat16Write -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Fat16
import Machine
import Maybe

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

maybe_text : Maybe.Maybe(CceText) -> CceText
maybe_text = |m| (match m {
	Just(t) => t
	None => "<none>"
})

entry_size : Maybe.Maybe(Fat16.Fat16DirEntry) -> I64
entry_size = |m| (match m {
	Just(e) => e.de_size
	None => (0 - 1)
})

maybe_bytes : Maybe.Maybe(List(I64)) -> CceText
maybe_bytes = |m| (match m {
	Just(bs) => show_bytes(bs, 0, U64.to_i64_wrap(List.len(bs)), "")
	None => "<none>"
})

show_bytes : List(I64), I64, I64, CceText -> CceText
show_bytes = |bs, i, n, acc| (if (i >= n) { acc } else { show_bytes(bs, (i + 1), n, CceText.concat(CceText.concat(acc, CceText.show_int((List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))), " ")) })

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Device.Block"])
	(machine1, machine__1) = Fat16.fat16_write_file!(machine, "HELLO.TXT", "Hello, disk!")
	ok = machine__1
	line!(CceText.printed(CceText.concat("wrote ", (if ok { "True" } else { "False" }))))
	(machine2, machine__2) = Fat16.file_exists!(machine1, "HELLO.TXT")
	there = machine__2
	line!(CceText.printed(CceText.concat("exists ", (if there { "True" } else { "False" }))))
	(machine3, machine__3) = Fat16.fat16_init!(machine2, 2048)
	vol = machine__3
	(machine4, machine__4) = Fat16.fat16_read_text!(machine3, vol, "HELLO.TXT")
	back = machine__4
	line!(CceText.printed(CceText.concat("readback ", maybe_text(back))))
	(machine5, machine__5) = Fat16.fat16_resolve_path!(machine4, vol, "HELLO.TXT")
	entry = machine__5
	line!(CceText.printed(CceText.concat("size ", CceText.show_int(entry_size(entry)))))
	(machine6, machine__6) = Fat16.fat16_write_binary_file!(machine5, "BIN.DAT", [1, 2, 3, 254])
	bok = machine__6
	line!(CceText.printed(CceText.concat("wrote-bin ", (if bok { "True" } else { "False" }))))
	(machine7, machine__7) = Fat16.fat16_read_bytes!(machine6, vol, "BIN.DAT")
	bytes = machine__7
	line!(CceText.printed(CceText.concat("bin ", maybe_bytes(bytes))))
	(machine8, machine__8) = Fat16.file_exists!(machine7, "NOPE.XXX")
	gone = machine__8
	line!(CceText.printed(CceText.concat("absent ", (if gone { "True" } else { "False" }))))
	Machine.halt!(machine8)
	Ok({})
}
