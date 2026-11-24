# The JavaScript subset as a command: one program's text in, what it
# prints out. The program is compiled (Compile.roc) and run on the bytecode
# VM (Vm.roc), built once on Roc's default platform. The command line is
# all the input a program has, and what it logs leaves by `echo!` as it
# logs it. It runs on JavaScript's own builtins alone, the library node
# has, so node is its oracle.
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
# A program the parser refuses, or one that stops with a fault, ends with a line
# `js: <why>` and exits 1; one that throws what nothing catches ends with a
# line `Uncaught <what node prints first> (line <n>)` and exits 1. A
# program using what the VM doesn't run yet ends with
# `js: unsupported (vm): <what>`.
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

# The core library logs and does nothing else: it has no canvas builtin to
# draw with and none that reads input. A function, not a constant: roc-types
# at the pin panics ("a hosted procedure has no host binding") on a
# top-level constant that holds an effectful lambda, which `roc` builds.
command_host : {} -> Canvas.Host
command_host = |{}| {
	emit!: |effect|
		match effect {
			Log(line) => echo!("${line}\n")
			_ => crash "js-vm: the core library has no canvas builtin"
		},
	pointer!: |_axis| crash "js-vm: the core library has no mouseX or mouseY",
	key!: |_key| crash "js-vm: the core library has no keyIsDown",
	collected!: |_heap| {},
}

run_program! : Str, Options => Try({}, [Exit(I8)])
run_program! = |src, options| {
	match Parser.program_of(src, Core) {
		Ok(tree) => match Compile.program(tree) {
			Ok(program) => {
				outcome = Vm.run!(
					command_host({}),
					program,
					{
						library: Core,
						steps: 200000000,
						effects: 1000000000000,
						collecting: options.collecting,
					},
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
