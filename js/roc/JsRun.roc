# The JavaScript subset as a command: one program's text in, what it prints
# out, built once on Roc's default platform.
#
#   js-run "<program>"
#
# The command line is all the input a program has. What it logs leaves by
# `echo!` as it logs it. It runs on JavaScript's own builtins alone, the
# library node has, so node is its oracle. A program the parser refuses, or
# one that stops with a fault, ends with a line `js: <why>` and exits 1; one
# that throws what nothing catches ends with a line `Uncaught <what node
# prints first> (line <n>)` and exits 1, as node does.
# js-count (JsCount.roc) is the same run with its counts after it.
import Canvas
import Interp
import Parser

main! = |arguments| {
	match arguments.get(0) {
		Ok(src) => run_program!(src)
		Err(OutOfBounds) => {
			echo!("usage: js-run \"<program>\"\n")
			Err(Exit(2))
		}
	}
}

# The core library logs and does nothing else: it has no canvas builtin to
# draw with and none that reads input. A function, not a constant: roc-types
# at the pin panics ("a hosted procedure has no host binding") on a
# top-level constant that holds an effectful lambda, which `roc` builds.
command_host : {} -> Canvas.Host
command_host = |{}| {
	emit!: |effect|
		match effect {
			Log(line) => echo!("${line}\n")
			_ => crash "js-run: the core library has no canvas builtin"
		},
	pointer!: |_axis| crash "js-run: the core library has no mouseX or mouseY",
	key!: |_key| crash "js-run: the core library has no keyIsDown",
}

run_program! : Str => Try({}, [Exit(I8)])
run_program! = |src| {
	match Parser.program_of(src, Core) {
		Ok(program) => {
			outcome = Interp.run!(
				command_host({}),
				program,
				Core,
				{ steps: 200000000, effects: 1000000000000 },
			)
			match outcome.status {
				Running => Ok({})
				Faulted(why) => {
					echo!("js: ${why}\n")
					Err(Exit(1))
				}
				Uncaught(line) => {
					echo!("${line}\n")
					Err(Exit(1))
				}
			}
		}
		Err(fault) => {
			echo!("js: ${fault.why} (line ${fault.line.to_str()}, column ${fault.column.to_str()})\n")
			Err(Exit(1))
		}
	}
}
