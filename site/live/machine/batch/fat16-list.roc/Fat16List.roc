app [main!] { pf: platform "../../../../../showell_repos/roc-apps/machine/batch/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# Fat16List -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Fat16
import Machine

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_list! : Str, List(Str), I64, I64 => {}
show_list! = |label, xs, i, n| (if (i >= n) { ({
	line!(Str.concat(label, " end"))
}) } else { ({
	line!(Str.concat(Str.concat(label, " "), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	show_list!(label, xs, (i + 1), n)
}) })

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Device.Block"])
	(machine1, machine__162) = Fat16.file_exists!(machine, "CODEX.CDX")
	hit = machine__162
	line!(Str.concat("exists-present ", (if hit { "True" } else { "False" })))
	(machine2, machine__163) = Fat16.file_exists!(machine1, "NOPE.XXX")
	miss = machine__163
	line!(Str.concat("exists-absent ", (if miss { "True" } else { "False" })))
	(machine3, machine__164) = Fat16.list_directories!(machine2, "")
	dirs = machine__164
	show_list!("rootdir", dirs, 0, U64.to_i64_wrap(List.len(dirs)))
	(machine4, machine__165) = Fat16.list_files!(machine3, "", "")
	files = machine__165
	show_list!("rootfile", files, 0, U64.to_i64_wrap(List.len(files)))
	(machine5, machine__166) = Fat16.list_files!(machine4, "EFI/BOOT", "")
	boot = machine__166
	show_list!("bootfile", boot, 0, U64.to_i64_wrap(List.len(boot)))
	(machine6, machine__167) = Fat16.list_files!(machine5, "", ".CDX")
	cdx = machine__167
	show_list!("extfilter", cdx, 0, U64.to_i64_wrap(List.len(cdx)))
	(machine7, machine__168) = Fat16.list_files!(machine6, "", ".ZZZ")
	nope = machine__168
	show_list!("extnomatch", nope, 0, U64.to_i64_wrap(List.len(nope)))
	Machine.halt!(machine7)
	Ok({})
}
