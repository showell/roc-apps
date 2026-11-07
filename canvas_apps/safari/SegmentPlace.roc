## A segment's place relative to the rider: ahead at a position on the road
## ahead, or just behind the rider, round the bend into the rider's segment.
## The bend behind is the route's, so a place doesn't carry it.
SegmentPlace := [Ahead(SegmentPlace.Position), JustBehind].{

	## How many segments ahead of the rider a segment is, counted from the
	## rider's own at 0. A Route.SegmentIndex says where a segment is in the
	## route instead.
	Position :: U32.{

		to_u32 : SegmentPlace.Position -> U32
		to_u32 = |SegmentPlace.Position.(n)| n

		## The rider's own segment.
		first : SegmentPlace.Position
		first = SegmentPlace.Position.(0)

		next : SegmentPlace.Position -> SegmentPlace.Position
		next = |SegmentPlace.Position.(n)| SegmentPlace.Position.(n + 1)

		## Every position on a road ahead of `count` segments, the rider's own
		## first.
		positions_in : { count : U32, .. } -> List(SegmentPlace.Position)
		positions_in = |{ count, .. }|
			List.from_iter(U32.until(0, count)).map(position_number)

		## Whether this position is the last one on a road ahead of `count`
		## segments.
		is_last_in : SegmentPlace.Position, { count : U32, .. } -> Bool
		is_last_in = |SegmentPlace.Position.(n), { count, .. }| n + 1 >= count

		## Whether this position is among the first `count` of the road ahead.
		is_within_first : SegmentPlace.Position, U32 -> Bool
		is_within_first = |SegmentPlace.Position.(n), count| n < count

		is_eq : _
	}

	is_eq : _
}

## The position `n` segments ahead of the rider's own.
position_number : U32 -> SegmentPlace.Position
position_number = |n| SegmentPlace.Position.(n)
