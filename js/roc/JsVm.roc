# The JavaScript subset on the bytecode VM, as a command: js-run's program
# compiled (Compile.roc) and run on the VM (Vm.roc) in place of the tree
# walker, built once on Roc's default platform.
#
#   js-vm "<program>"
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
	match arguments.get(0) {
		Ok(src) => run_program!(src)
		Err(OutOfBounds) => {
			echo!("usage: js-vm \"<program>\"\n")
			Err(Exit(2))
		}
	}
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

run_program! : Str => Try({}, [Exit(I8)])
run_program! = |src| {
	match Parser.program_of(src, Core) {
		Ok(tree) => match Compile.program(tree) {
			Ok(program) => {
				ending = Vm.run!(
					command_host({}),
					program,
					{ steps: 200000000, effects: 1000000000000 },
				)
				match ending {
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
