# The JavaScript subset as a command: one program's text in, what it prints
# out, built once on Roc's default platform.
#
#   js-run "<program>"
#
# The interpreter is a pure function, so the command line is all the input
# it needs. What the program logs leaves by `echo!`. A program the parser
# refuses, or one that stops with a fault, ends with a line `js: <why>` and
# exits 1. The run's counts (statements run, cells and scopes at the end) go
# to stderr by `dbg`, so stdout stays the program's own.
import Interp
import Parser

main! = |args| {
	src = args.get(0) ?? ""
	match Parser.program_of(src) {
		Ok(program) => {
			outcome = Interp.run(program, 200000000)
			echo!(outcome.out)
			dbg { steps: outcome.steps, cells: outcome.cells, scopes: outcome.scopes }
			match outcome.status {
				Running => Ok({})
				Faulted(why) => {
					echo!("js: ${why}\n")
					Err(Exit(1))
				}
			}
		}
		Err(f) => {
			echo!("js: ${f.why} (line ${f.line.to_str()}, column ${f.col.to_str()})\n")
			Err(Exit(1))
		}
	}
}
