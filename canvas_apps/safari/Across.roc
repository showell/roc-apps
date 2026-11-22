## A place across the road, in metres from the middle of the road, growing to the
## right. A distance added to a place gives a place, and two places give the
## distance between them, but two places can't be added. A place across the road
## can't be passed as a place along it.
import Distance

Across :: F64.{

	metres : F64 -> Across
	metres = |m| Across.(m)

	to_metres : Across -> F64
	to_metres = |Across.(across)| across

	## The middle of the road.
	middle : Across
	middle = Across.(0.0)

	## The place `distance` to the right of the middle of the road.
	right_of_middle : Distance -> Across
	right_of_middle = |distance| Across.(distance.to_metres())

	## The place `distance` to the left of the middle of the road.
	left_of_middle : Distance -> Across
	left_of_middle = |distance| Across.(0.0 - distance.to_metres())

	## How far this place is from the middle of the road, to either side.
	distance_from_middle : Across -> Distance
	distance_from_middle = |Across.(across)| Distance.metres(across.abs())

	## The place `distance` further right.
	plus : Across, Distance -> Across
	plus = |Across.(across), distance| Across.(across + distance.to_metres())

	## The place `distance` further left.
	minus : Across, Distance -> Across
	minus = |Across.(across), distance| Across.(across - distance.to_metres())

	## How far this place is to the right of `other`: negative when it is to
	## the left.
	distance_from : Across, Across -> Distance
	distance_from = |Across.(across), Across.(other)| Distance.metres(across - other)

	## The place further left of this one and `other`.
	min : Across, Across -> Across
	min = |Across.(across), Across.(other)| Across.(F64.min(across, other))

	## The place further right of this one and `other`.
	max : Across, Across -> Across
	max = |Across.(across), Across.(other)| Across.(F64.max(across, other))

	is_gt : Across, Across -> Bool
	is_gt = |Across.(across), Across.(other)| across > other

	is_gte : Across, Across -> Bool
	is_gte = |Across.(across), Across.(other)| across >= other

	is_lt : Across, Across -> Bool
	is_lt = |Across.(across), Across.(other)| across < other

	is_lte : Across, Across -> Bool
	is_lte = |Across.(across), Across.(other)| across <= other

	is_eq : _
}

## Just under, at and just over 2.5 m, and how `<`, `<=`, `>`, `>=` and `==`
## answer against 2.5 m there.
expect
	[
		(2.0, [True, True, False, False, False]),
		(2.5, [False, True, False, True, True]),
		(3.0, [False, False, True, True, False]),
	].all(
		|(metres, want)| {
			across = Across.metres(metres)
			held = Across.metres(2.5)
			[
				across < held,
				across <= held,
				across > held,
				across >= held,
				across == held,
			] == want
		},
	)
