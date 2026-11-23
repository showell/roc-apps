# The canvas playground's recording host: a program run as the page runs it,
# its effects printed one a line, in the order the program made them, rather
# than painted.
#
#   js-canvas <frames> "<program>" [<keys>]
#
# It runs the program on the canvas library, held to the page's rails
# (`Canvas.run_limits`, then `Canvas.frame_limits` for each frame), then calls
# its `frame(t)` for the frames asked, t being the frame's number over
# `Canvas.frames_per_second`, as on the page. Each effect is its line
# (`Canvas.line_of`); each read is a line too, `read mouseX 200` or
# `read keyIsDown ArrowLeft up`, so a log holds every call the program made
# of its host. A line `frame <n> <t>` starts each frame.
#
# The pointer rests at the canvas's middle. `<keys>` says which keys are down
# in each frame: the frames' sets parted by commas, the keys in a set by `+`
# (`,ArrowRight,ArrowRight+ArrowUp`: none in frame 0, then ArrowRight, then
# both). A frame past the list, and the run before the first frame, have no
# key down.
#
# A program the parser refuses, or one that stops with a fault, ends with a
# line `js: <why>` and exits 1, as js-run's does.
import Canvas
import Interp
import NumberText
import Parser

main! = |arguments| {
	match (arguments.get(0), arguments.get(1)) {
		(Ok(count_text), Ok(src)) => match U64.from_str(count_text) {
			Ok(count) => record_program!(
				src,
				{ frames: count, keys: (arguments.get(2) ?? "").split_on(",") },
			)
			Err(_) => usage!({})
		}
		_ => usage!({})
	}
}

usage! : {} => Try({}, [Exit(I8)])
usage! = |{}| {
	echo!("usage: js-canvas <frames> \"<program>\" [<keys>]\n")
	Err(Exit(2))
}

# The host for a run or a frame, which answers `keys_down` as the keys held.
recording_host : List(Str) -> Canvas.Host
recording_host = |keys_down| {
	emit!: |effect| echo!("${Canvas.line_of(effect)}\n"),
	pointer!: |axis| {
		at = 200.0
		name = match axis {
			X => "mouseX"
			Y => "mouseY"
		}
		echo!("read ${name} ${NumberText.text_for(at)}\n")
		at
	},
	key!: |key| {
		state = if keys_down.contains(key) {
			Down
		} else {
			Up
		}
		said = match state {
			Down => "down"
			Up => "up"
		}
		echo!("read keyIsDown ${key} ${said}\n")
		state
	},
}

record_program! : Str, { frames : U64, keys : List(Str) } => Try({}, [Exit(I8)])
record_program! = |src, { frames, keys: key_frames }| {
	match Parser.program_of(src, Canvas) {
		Ok(program) => {
			var $session = Interp.start!(recording_host([]), program, Canvas, Canvas.run_limits)
			var $n = 0
			while $n < frames and Interp.outcome_of($session.machine).status == Running {
				t = $n.to_f64() / Canvas.frames_per_second.to_f64()
				match $session.frame {
					Frame(_) => {
						echo!("frame ${$n.to_str()} ${NumberText.text_for(t)}\n")
						keys = (key_frames.get($n) ?? "").split_on("+")
						$session = Interp.frame!(
							recording_host(keys),
							$session,
							t,
							Canvas.frame_limits,
						)
					}
					NoFrame => {}
				}
				$n = $n + 1
			}
			match Interp.outcome_of($session.machine).status {
				Running => Ok({})
				Faulted(why) => {
					echo!("js: ${why}\n")
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
