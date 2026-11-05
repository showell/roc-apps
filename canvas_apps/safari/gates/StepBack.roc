# Does one step back go back exactly one step? Natively, at depths either side
# of the history's cap.
#
# Hand-written, like ShapesFrame and RasterFrame beside it. It exists because
# the answer used to be no: `advance` stopped recording once its list was full,
# so the history was the FIRST 2048 frames and a step back from frame 3000
# landed on 2047. Pressing J -- which advances until the segment changes --
# fills that list in a moment, which is how it was found.
#
#   roc build --opt=dev StepBack.roc --output=<bin>; <bin>
app [main!] {
	game: "../game.roc",
	lib: "../../lib/main.roc",
}

import game.Tour

main! = |_args| {
	var $out = ""
	var $bad = 0
	for steps in [10, 1000, 2047, 2048, 2049, 3000, 5000] {
		var $tour = Tour.initial
		var $k = 0
		while $k < steps {
			$tour = Tour.advance($tour)
			$k = $k + 1
		}
		here = $tour.moment.clock
		there = Tour.back($tour).moment.clock
		ok = there.next() == here
		$bad = if ok {
			$bad
		} else {
			$bad + 1
		}
		verdict = if (ok) "ok  " else "BAD "
		clocks = "clock ${here.to_str()}, one back -> ${there.to_str()}"
		$out = Str.concat($out, "${verdict}after ${I64.to_str(steps)} steps: ${clocks}\n")
	}
	echo!(
		Str.concat(
			$out,
			if $bad == 0 {
				"every step back went back one step\n"
			} else {
				"${I64.to_str($bad)} did not go back one step\n"
			},
		),
	)
	Ok({})
}
