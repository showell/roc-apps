## A place along one segment of the road, in metres from that segment's start,
## which is the only origin an `Along` has. It may lie before the start or past
## the end, as a point on the next segment does when it is measured on this one.
## A place measured from anywhere else, such as the segment's end, is a
## `Distance` named for where it is from, and becomes an `Along` only through
## the segment's length.
## `Along` and `Across` mirror `Angle.Bearing` and `Angle.Turn`: a distance added
## to a place gives a place, and two places give the distance between them, but
## two places can't be added. A place along the road can't be passed as a place
## across it.
import Distance

Along :: F64.{

	metres : F64 -> Along
	metres = |metres| Along.(metres)

	to_metres : Along -> F64
	to_metres = |Along.(a)| a

	## The segment's start.
	start : Along
	start = Along.(0.0)

	## The place this far from the segment's start.
	at : Distance -> Along
	at = |distance| Along.(distance.to_metres())

	## How far this place is from the segment's start.
	from_start : Along -> Distance
	from_start = |Along.(a)| Distance.metres(a)

	## The place `distance` further along.
	plus : Along, Distance -> Along
	plus = |Along.(a), distance| Along.(a + distance.to_metres())

	## The place `distance` back along.
	minus : Along, Distance -> Along
	minus = |Along.(a), distance| Along.(a - distance.to_metres())

	## How far this place is ahead of `other`: negative when it is behind.
	distance_from : Along, Along -> Distance
	distance_from = |Along.(a), Along.(other)| Distance.metres(a - other)

	is_gt : Along, Along -> Bool
	is_gt = |Along.(a), Along.(other)| a > other

	is_gte : Along, Along -> Bool
	is_gte = |Along.(a), Along.(other)| a >= other

	is_lt : Along, Along -> Bool
	is_lt = |Along.(a), Along.(other)| a < other

	is_lte : Along, Along -> Bool
	is_lte = |Along.(a), Along.(other)| a <= other

	is_eq : _
}

expect Along.start.to_metres() == 0.0
expect Along.at(Distance.metres(7.5)).to_metres() == 7.5
expect Along.metres(7.5).from_start().to_metres() == 7.5
expect Along.metres(7.5).plus(Distance.metres(2.0)).to_metres() == 9.5
expect Along.metres(7.5).minus(Distance.metres(2.0)).to_metres() == 5.5
expect Along.metres(7.5).distance_from(Along.metres(2.0)).to_metres() == 5.5
expect Along.metres(2.0).distance_from(Along.metres(7.5)).to_metres() == -5.5

## Just under, at and just over 2.5 m, and how `<`, `<=`, `>`, `>=` and `==`
## answer against 2.5 m there.
expect
	[
		(2.0, [True, True, False, False, False]),
		(2.5, [False, True, False, True, True]),
		(3.0, [False, False, True, True, False]),
	].all(
		|(metres, want)| {
			along = Along.metres(metres)
			held = Along.metres(2.5)
			[
				along < held,
				along <= held,
				along > held,
				along >= held,
				along == held,
			] == want
		},
	)
