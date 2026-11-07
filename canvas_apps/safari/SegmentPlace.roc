## A segment's place relative to the rider: ahead at a position on the road
## ahead, or just behind the rider, round the bend into the rider's segment.
import Geom

SegmentPlace := [Ahead(SegmentPlace.Position), JustBehind(Geom.Bend)].{

	## How many segments ahead of the rider a segment is, counted from the
	## rider's own at 0. A Route.SegmentIndex says where a segment is in the
	## route instead.
	Position :: U32.{

		number : U32 -> SegmentPlace.Position
		number = |n| SegmentPlace.Position.(n)

		to_u32 : SegmentPlace.Position -> U32
		to_u32 = |SegmentPlace.Position.(n)| n

		to_i64 : SegmentPlace.Position -> I64
		to_i64 = |SegmentPlace.Position.(n)| n.to_i64()

		## The rider's own segment.
		first : SegmentPlace.Position
		first = SegmentPlace.Position.(0)

		next : SegmentPlace.Position -> SegmentPlace.Position
		next = |SegmentPlace.Position.(n)| SegmentPlace.Position.(n + 1)

		## Every position on a road ahead of `count` segments, the rider's own
		## first.
		positions_in : { count : U32, .. } -> List(SegmentPlace.Position)
		positions_in = |{ count, .. }|
			List.from_iter(U32.until(0, count)).map(SegmentPlace.Position.number)

		## Whether this position is the last one on a road ahead of `count`
		## segments.
		is_last_in : SegmentPlace.Position, { count : U32, .. } -> Bool
		is_last_in = |SegmentPlace.Position.(n), { count, .. }| n + 1 >= count

		## Whether a road ahead of `count` segments stops before this position.
		is_past_end_of : SegmentPlace.Position, { count : U32, .. } -> Bool
		is_past_end_of = |SegmentPlace.Position.(n), { count, .. }| n >= count

		## Whether this position is among the first `count` of the road ahead.
		is_within_first : SegmentPlace.Position, U32 -> Bool
		is_within_first = |SegmentPlace.Position.(n), count| n < count

		is_eq : _
	}

	is_eq : _
}

expect SegmentPlace.Position.number(3).to_i64() == 3
expect SegmentPlace.Position.first.next().to_i64() == 1
