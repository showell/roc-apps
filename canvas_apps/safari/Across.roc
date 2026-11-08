## A place across the road, in metres from the middle of the road, growing to the
## right. A distance added to a place gives a place, and two places give the
## distance between them, but two places can't be added. A place across the road
## can't be passed as a place along it.
import Distance

Across :: F64.{

	metres : F64 -> Across
	metres = |metres| Across.(metres)

	to_metres : Across -> F64
	to_metres = |Across.(a)| a

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
	distance_from_middle = |Across.(a)| Distance.metres(a.abs())

	## The place `distance` further right.
	plus : Across, Distance -> Across
	plus = |Across.(a), distance| Across.(a + distance.to_metres())

	## The place `distance` further left.
	minus : Across, Distance -> Across
	minus = |Across.(a), distance| Across.(a - distance.to_metres())

	## How far this place is to the right of `other`: negative when it is to
	## the left.
	distance_from : Across, Across -> Distance
	distance_from = |Across.(a), Across.(other)| Distance.metres(a - other)

	## The place further left of this one and `other`.
	min : Across, Across -> Across
	min = |Across.(a), Across.(other)| Across.(a.min(other))

	## The place further right of this one and `other`.
	max : Across, Across -> Across
	max = |Across.(a), Across.(other)| Across.(a.max(other))

	is_gt : Across, Across -> Bool
	is_gt = |Across.(a), Across.(other)| a > other

	is_gte : Across, Across -> Bool
	is_gte = |Across.(a), Across.(other)| a >= other

	is_lt : Across, Across -> Bool
	is_lt = |Across.(a), Across.(other)| a < other

	is_lte : Across, Across -> Bool
	is_lte = |Across.(a), Across.(other)| a <= other

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
