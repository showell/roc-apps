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

import game.SafariRide

main! = |_args| {
	var $out = ""
	var $bad = 0
	for steps in [10, 1000, 2047, 2048, 2049, 3000, 5000] {
		var $m = SafariRide.init
		var $k = 0
		while $k < steps {
			$m = SafariRide.advance($m)
			$k = $k + 1
		}
		here = $m.ride.clock
		there = SafariRide.back($m).ride.clock
		ok = there == here - 1.0
		$bad = if ok {
			$bad
		} else {
			$bad + 1
		}
		verdict = if (ok) "ok  " else "BAD "
		clocks = "clock ${F64.to_str(here)}, one back -> ${F64.to_str(there)}"
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
