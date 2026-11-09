## What a segment's encounter does to the rider. The rider reacts only to the
## encounter on their own segment, and this is the one place that knows which
## encounters ask anything of them. A cat in the road stops the rider opening
## the throttle, without braking, and draws their eye. A bird asks nothing. The
## pigs' gaze is no encounter, and is Gaze's.
import Acceleration
import Animation
import Attention
import CatCrossing
import Easing
import Encounter
import lib.Fraction
import Steps
import ThrottleLimit

EncounterReaction :: [].{

	## What `encounter`, at `stage`, asks of the throttle of a rider on its
	## segment: while a cat crosses, the rider eases off, holding the
	## acceleration at none, which stops them speeding up and never brakes.
	encounter_throttle : Encounter, Animation.Stage -> ThrottleLimit
	encounter_throttle = |encounter, stage|
		match encounter {
			CatCrosses(_) =>
				match stage {
					Playing(_) => AtMost(Acceleration.steady)
					Waiting | Past(_) => NoLimit
				}
			BirdHere(_) | QuietRoad => NoLimit
		}

	## How hard `encounter`, at `stage`, holds the eye of a rider on its
	## segment.
	encounter_attention : Encounter, Animation.Stage -> Attention
	encounter_attention = |encounter, stage|
		match encounter {
			CatCrosses(_) => cat_attention(stage)
			BirdHere(_) | QuietRoad => Attention.none
		}
}

## How hard a crossing cat holds the rider's eye at `stage`: rising to the
## cat's peak as it crosses, then fading once it is across.
cat_attention : Animation.Stage -> Attention
cat_attention = |stage|
	match stage {
		Waiting => Attention.none
		Playing(steps_in) => {
			progress = Fraction.of(steps_in.ratio_to(CatCrossing.crossing_span.length))
			CatCrossing.peak_attention.scaled_by(Easing.smoothstep(progress))
		}
		Past(steps_past) => {
			faded = Fraction.clamp(steps_past.ratio_to(attention_fade))
			CatCrossing.peak_attention.scaled_by(Easing.smoothstep(faded).complement())
		}
	}

## Over how many steps the rider's eye lets a cat go, from when the crossing
## ends: 83 steps, chosen by eye, about 80 metres past the cat at a metre a step.
attention_fade : Steps
attention_fade = Steps.of(83)

## How hard the cat holds the eye at `stage`.
attention_at : Animation.Stage -> F64
attention_at = |stage| cat_attention(stage).to_f64()

expect attention_at(Waiting) == 0.0
expect attention_at(Playing(Steps.zero)) == 0.0
expect attention_at(Playing(Steps.of(19))) == 0.9
expect attention_at(Past(Steps.zero)) == 1.8
expect attention_at(Past(Steps.of(42))) > 0.0
expect attention_at(Past(Steps.of(42))) < 1.8
expect attention_at(Past(Steps.of(83))) == 0.0
expect attention_at(Past(Steps.of(200))) == 0.0
