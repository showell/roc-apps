## A place along a segment of the road, in metres from the segment's start.
## `Along` and `Across` mirror `Angle.Bearing` and `Angle.Turn`: a distance added
## to a place gives a place, and two places give the distance between them, but
## two places can't be added. A place along the road can't be passed as a place
## across it.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
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
