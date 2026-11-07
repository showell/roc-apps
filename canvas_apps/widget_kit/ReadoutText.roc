## The words a widget's readout gives a number: a distance to a tenth, a fraction
## as a percentage, a count with commas, and where an animation has got to.
import game.Animation
import game.Distance
import game.Fraction

ReadoutText :: [].{

	## Where an animation has got to, in words.
	stage_text : Animation.Stage -> Str
	stage_text = |stage|
		match stage {
			Waiting => "Waiting"
			Playing(progress) => "Playing: ${percent_text(progress)}"
			Past(_) => "Past"
		}

	## A number to one decimal place, with a minus sign when it's negative.
	tenths_text : F64 -> Str
	tenths_text = |number| {
		tenths = (number.abs() * 10.0 + 0.5).to_u64_wrap()
		digits = "${(tenths // 10).to_str()}.${(tenths % 10).to_str()}"
		if number < 0.0 {
			"-${digits}"
		} else {
			digits
		}
	}

	## A fraction as a whole percentage, rounded down.
	percent_text : Fraction -> Str
	percent_text = |fraction| "${(fraction.to_f64() * 100.0).to_i64_wrap().to_str()}%"

	## A count as the book writes it, with commas.
	count_text : U64 -> Str
	count_text = |count| {
		thousands = count // 1000
		rest = count % 1000
		if thousands == 0 {
			rest.to_str()
		} else if rest < 10 {
			"${count_text(thousands)},00${rest.to_str()}"
		} else if rest < 100 {
			"${count_text(thousands)},0${rest.to_str()}"
		} else {
			"${count_text(thousands)},${rest.to_str()}"
		}
	}
}

expect ReadoutText.stage_text(Waiting) == "Waiting"
expect ReadoutText.stage_text(Playing(Fraction.of(0.5))) == "Playing: 50%"
expect ReadoutText.stage_text(Past(Distance.metres(1.0))) == "Past"

expect ReadoutText.tenths_text(0.0) == "0.0"
expect ReadoutText.tenths_text(0.04) == "0.0"
expect ReadoutText.tenths_text(0.06) == "0.1"
expect ReadoutText.tenths_text(21.0) == "21.0"
expect ReadoutText.tenths_text(9.96) == "10.0"

# A negative rounds as its size does, with the sign in front.
expect ReadoutText.tenths_text(-0.04) == "-0.0"
expect ReadoutText.tenths_text(-0.06) == "-0.1"
expect ReadoutText.tenths_text(-1.5) == "-1.5"

expect ReadoutText.percent_text(Fraction.zero) == "0%"
expect ReadoutText.percent_text(Fraction.of(0.529)) == "52%"
expect ReadoutText.percent_text(Fraction.whole) == "100%"

expect ReadoutText.count_text(0) == "0"
expect ReadoutText.count_text(999) == "999"
expect ReadoutText.count_text(1000) == "1,000"
expect ReadoutText.count_text(1005) == "1,005"
expect ReadoutText.count_text(1050) == "1,050"
expect ReadoutText.count_text(2198) == "2,198"
expect ReadoutText.count_text(1000000) == "1,000,000"
