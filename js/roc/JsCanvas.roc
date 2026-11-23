# The canvas playground's recording host: a program run as the page runs it,
# its effects printed one a line, in the order the program made them, rather
# than painted.
#
#   js-canvas <frames> "<program>" [<keys>] [<clicks>]
#
# It runs the program on the canvas library, held to the page's rails
# (`Canvas.run_limits`, then `Canvas.frame_limits` for each frame), then ticks
# its clock for the frames asked (`Interp.tick!`), as the page does: each
# tick runs what is due by the frame's time, t being the frame's number over
# `Canvas.frames_per_second`, the clicks first, then the timers and the
# program's `frame(t)` in the order of their times. Each effect is its line
# (`Canvas.line_of`); each read is a line too, `read mouseX 200` or
# `read keyIsDown ArrowLeft up`, so a log holds every call the program made
# of its host. A line `frame <n> <t>` starts each tick; the ticks end when
# the program has nothing waiting (`Interp.waits`).
#
# The pointer rests at the canvas's middle. `<keys>` says which keys are down
# in each frame: the frames' sets parted by commas, the keys in a set by `+`
# (`,ArrowRight,ArrowRight+ArrowUp`: none in frame 0, then ArrowRight, then
# both). A frame past the list, and the run before the first frame, have no
# key down. `<clicks>` says where the canvas is clicked and before which
# frame: `<frame>:<x>:<y>`, parted by commas (`3:120:80,9:300:200`). Each is
# a line `click <x> <y>`, before its frame's line.
#
# A program the parser refuses, or one that stops with a fault, ends with a
# line `js: <why>` and exits 1, as js-run's does.
import Canvas
import Interp
import NumberText
import Parser

main! = |arguments| {
	match (arguments.get(0), arguments.get(1)) {
		(Ok(count_text), Ok(src)) => match (
			U64.from_str(count_text),
			clicks_of(text_or_none(arguments, 3)),
		) {
			(Ok(count), Ok(clicks)) => record_program!(
				src,
				{
					frames: count,
					keys: text_or_none(arguments, 2).split_on(","),
					clicks: clicks,
				},
			)
			_ => print_usage!({})
		}
		_ => print_usage!({})
	}
}

# The text at `position`, or "" where the list stops short of it: an
# argument left out, or a frame past the keys given, is none.
text_or_none : List(Str), U64 -> Str
text_or_none = |texts, position|
	match texts.get(position) {
		Ok(text) => text
		Err(OutOfBounds) => ""
	}

print_usage! : {} => Try({}, [Exit(I8)])
print_usage! = |{}| {
	echo!("usage: js-canvas <frames> \"<program>\" [<keys>] [<clicks>]\n")
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

Click : {
	frame : U64,
	x : F64,
	y : F64,
}

# The clicks `<frame>:<x>:<y>,...` names, or why not.
clicks_of : Str -> Try(List(Click), [BadClicks])
clicks_of = |text|
	if text == "" {
		Ok([])
	} else {
		var $clicks = []
		for each in text.split_on(",") {
			match each.split_on(":") {
				[frame_text, x_text, y_text] => match (
					U64.from_str(frame_text),
					F64.from_str(x_text),
					F64.from_str(y_text),
				) {
					(
						Ok(frame),
						Ok(x),
						Ok(y),
					) => {
						$clicks = $clicks.append({
							frame: frame,
							x: x,
							y: y,
						})
					}
					_ => return Err(BadClicks)
				}
				_ => return Err(BadClicks)
			}
		}
		Ok($clicks)
	}

record_program! : Str,
{
	frames : U64,
	keys : List(Str),
	clicks : List(Click),
} => Try({}, [Exit(I8)])
record_program! = |src, { frames, keys: key_frames, clicks }| {
	match Parser.program_of(src, Canvas) {
		Ok(program) => {
			var $session = Interp.start!(recording_host([]), program, Canvas, Canvas.run_limits)
			var $n = 0
			while $n < frames and Interp.waits($session) {
				for click in clicks {
					if click.frame == $n {
						echo!("click ${NumberText.text_for(click.x)} ${NumberText.text_for(click.y)}\n")
						$session = Interp.with_click($session, click.x, click.y)
					}
				}
				seconds = Interp.frame_time($n)
				echo!("frame ${$n.to_str()} ${NumberText.text_for(seconds)}\n")
				keys = text_or_none(key_frames, $n).split_on("+")
				$session = Interp.tick!(
					recording_host(keys),
					$session,
					seconds,
					Canvas.frame_limits,
				)
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
