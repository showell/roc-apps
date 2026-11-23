# The JavaScript subset as a command: one program's text in, what it prints
# out, built once on Roc's default platform.
#
#   js-run "<program>"
#
# The interpreter is a pure function, so the command line is all the input
# it needs. What the program logs leaves by `echo!`. A program the parser
# refuses, or one that stops with a fault, ends with a line `js: <why>` and
# exits 1. js-count (JsCount.roc) is the same run with its counts after it.
import Interp
import Parser

main! = |args| {
	match args.get(0) {
		Ok(src) => run_program!(src)
		Err(OutOfBounds) => {
			echo!("usage: js-run \"<program>\"\n")
			Err(Exit(2))
		}
	}
}

run_program! : Str => Try({}, [Exit(I8)])
run_program! = |src| {
	match Parser.program_of(src) {
		Ok(program) => {
			outcome = Interp.run(program, 200000000)
			echo!(outcome.out)
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
