# The JavaScript subset as a command that counts: js-run's run, then one
# more line, the statements the program ran and the cells and scopes the
# machine held at its end. The allocation probes (js/probes.shale) read it.
#
#   js-count "<program>"
import Interp
import Parser

main! = |args| {
	match args.get(0) {
		Ok(src) => count_program!(src)
		Err(OutOfBounds) => {
			echo!("usage: js-count \"<program>\"\n")
			Err(Exit(2))
		}
	}
}

count_program! : Str => Try({}, [Exit(I8)])
count_program! = |src| {
	match Parser.program_of(src) {
		Ok(program) => {
			outcome = Interp.run(program, 2000000000)
			echo!(outcome.out)
			echo!("js-count: steps ${outcome.steps.to_str()} cells ${outcome.cells.to_str()} scopes ${outcome.scopes.to_str()}\n")
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
