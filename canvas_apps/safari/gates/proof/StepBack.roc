# Does one step back go back exactly one step, and do steps back from the
# ride's finish reach its start? Natively, over the whole ride.
#
# Hand-written, like ShapesFrame and RasterFrame beside it. A tour keeps every
# instant from the ride's start, so a step back at any depth lands one step
# back, and as many steps back as the ride took land on step 0, where one more
# leaves it. The finishing step moves with every physics change, so it isn't
# printed.
#
#   roc build --opt=dev StepBack.roc --output=<bin>; <bin>
app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Clock
import game.Tour

main! = |_args| {
	var $out = ""
	var $bad = 0.I64
	var $tour = Tour.initial
	var $k = 0
	for steps in [10.I64, 1000, 3000, 5000] {
		while $k < steps {
			$tour = $tour.step_forward()
			$k = $k + 1
		}
		here = $tour.instant().clock
		there = $tour.step_back().instant().clock
		ok = there.next() == here
		if !ok {
			$bad = $bad + 1
		}
		clocks = "clock ${here.to_str()}, one back -> ${there.to_str()}"
		$out = Str.concat($out, "${verdict_of(ok)}after ${steps.to_str()} steps: ${clocks}\n")
	}
	while !$tour.instant().rider.is_finished($tour.route()) {
		$tour = $tour.step_forward()
	}
	finish = $tour.instant().clock
	one_back = $tour.step_back().instant().clock
	finish_ok = one_back.next() == finish
	if !finish_ok {
		$bad = $bad + 1
	}
	$out = Str.concat($out, "${verdict_of(finish_ok)}at the finish: one back went back one step\n")
	var $backs = 0
	while $backs < finish.steps_since(Clock.start).to_u32() {
		$tour = $tour.step_back()
		$backs = $backs + 1
	}
	at_start = $tour.instant().clock
	past_start = $tour.step_back().instant().clock
	start_ok = at_start == Clock.start and past_start == Clock.start
	if !start_ok {
		$bad = $bad + 1
	}
	$out = Str.concat(
		$out,
		"${verdict_of(start_ok)}from the finish, as many steps back as the ride took: clock ${at_start.to_str()}, one more -> ${past_start.to_str()}\n",
	)
	echo!(
		Str.concat(
			$out,
			if $bad == 0 {
				"every step back went back one step\n"
			} else {
				"${$bad.to_str()} did not go back one step\n"
			},
		),
	)
	Ok({})
}

verdict_of : Bool -> Str
verdict_of = |ok|
	if ok {
		"ok  "
	} else {
		"BAD "
	}
