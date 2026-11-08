## Where a segment lies, seen from the rider: ahead at a position on the road
## ahead, the rider's own first, or just behind the rider, round the bend into
## the rider's segment. The bend behind is the route's, so a
## SegmentFromRider doesn't carry it. A RoutePlace says where something is in
## the route instead.
SegmentFromRider := [Ahead(SegmentFromRider.Position), JustBehind].{

	## How many segments ahead of the rider a segment is, counted from the
	## rider's own at 0. A Route.SegmentIndex says where a segment is in the
	## route instead.
	Position :: U32.{

		to_u32 : SegmentFromRider.Position -> U32
		to_u32 = |SegmentFromRider.Position.(n)| n

		## The rider's own segment.
		first : SegmentFromRider.Position
		first = SegmentFromRider.Position.(0)

		next : SegmentFromRider.Position -> SegmentFromRider.Position
		next = |SegmentFromRider.Position.(n)| SegmentFromRider.Position.(n + 1)

		## Every position on a road ahead of `count` segments, the rider's own
		## first.
		positions_in : { count : U32, .. } -> List(SegmentFromRider.Position)
		positions_in = |{ count, .. }|
			List.from_iter(U32.until(0, count)).map(position_number)

		## Whether this position is the last one on a road ahead of `count`
		## segments.
		is_last_in : SegmentFromRider.Position, { count : U32, .. } -> Bool
		is_last_in = |SegmentFromRider.Position.(n), { count, .. }| n + 1 >= count

		## Whether this position is among the first `count` of the road ahead.
		is_within_first : SegmentFromRider.Position, U32 -> Bool
		is_within_first = |SegmentFromRider.Position.(n), count| n < count

		is_eq : _
	}

	is_eq : _
}

## The position `n` segments ahead of the rider's own.
position_number : U32 -> SegmentFromRider.Position
position_number = |n| SegmentFromRider.Position.(n)
