# The JavaScript subset on the bytecode VM, as a command: js-run's program
# compiled (Compile.roc) and run on the VM (Vm.roc) in place of the tree
# walker, built once on Roc's default platform.
#
#   js-vm "<program>" [--collect-at-every-allocation] [--counts]
#
# `--collect-at-every-allocation` runs the collector after every instruction
# that allocates, in place of when the heap has doubled, so a root the
# collector misses shows on any program that allocates.
# `--counts` adds one last line, `js-vm: steps <n> cells <n> live <n>
# collections <n>`: the steps run, the heap's length, the cells still
# reached at the end, and the collections run (js/heaps.shale reads it).
#
# It prints what js-run prints and ends as js-run ends: a program the
# parser refuses, or one that stops with a fault, ends with a line
# `js: <why>` and exits 1; one that throws what nothing catches ends with a
# line `Uncaught <what node prints first> (line <n>)` and exits 1. A
# program using what the VM doesn't run yet ends with
# `js: unsupported (vm): <what>`, never on the walker.
import Canvas
import Compile
import Parser
import Vm

main! = |arguments| {
	match (arguments.get(0), options_of(arguments.drop_first(1))) {
		(Ok(src), Ok(options)) => run_program!(src, options)
		_ => {
			echo!("usage: js-vm \"<program>\" [--collect-at-every-allocation] [--counts]\n")
			Err(Exit(2))
		}
	}
}

Options : { collecting : [Doubling, EveryAllocation], counting : [Counts, NoCounts] }

options_of : List(Str) -> Try(Options, [Unknown(Str)])
options_of = |words| {
	var $options = Ok({ collecting: Doubling, counting: NoCounts })
	for word in words {
		$options = match ($options, word) {
			(Ok(so_far), "--collect-at-every-allocation") => Ok({ ..so_far, collecting: EveryAllocation })
			(Ok(so_far), "--counts") => Ok({ ..so_far, counting: Counts })
			(Ok(_), _) => Err(Unknown(word))
			(Err(unknown), _) => Err(unknown)
		}
	}
	$options
}

# The core library logs and does nothing else. A function for js-run's
# reason (JsRun.roc's `command_host`).
command_host : {} -> Canvas.Host
command_host = |{}| {
	emit!: |effect|
		match effect {
			Log(line) => echo!("${line}\n")
			_ => crash "js-vm: the core library has no canvas builtin"
		},
	pointer!: |_axis| crash "js-vm: the core library has no mouseX or mouseY",
	key!: |_key| crash "js-vm: the core library has no keyIsDown",
}

run_program! : Str, Options => Try({}, [Exit(I8)])
run_program! = |src, options| {
	match Parser.program_of(src, Core) {
		Ok(tree) => match Compile.program(tree) {
			Ok(program) => {
				outcome = Vm.run!(
					command_host({}),
					program,
					{ steps: 200000000, effects: 1000000000000, collecting: options.collecting },
				)
				match options.counting {
					Counts => echo!("js-vm: steps ${outcome.steps.to_str()} cells ${outcome.cells.to_str()} live ${outcome.live.to_str()} collections ${outcome.collections.to_str()}\n")
					NoCounts => {}
				}
				match outcome.ending {
					Finished => Ok({})
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
			Err(Unsupported(why)) => {
				echo!("js: ${why}\n")
				Err(Exit(1))
			}
		}
		Err(fault) => {
			echo!("js: ${fault.why} (line ${fault.line.to_str()}, column ${fault.column.to_str()})\n")
			Err(Exit(1))
		}
	}
}
