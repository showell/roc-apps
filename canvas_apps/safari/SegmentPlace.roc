## A segment's place relative to the rider: ahead at a position on the road
## ahead, or just behind the rider, round the bend into the rider's segment.
import Geom

SegmentPlace := [Ahead(SegmentPlace.Position), JustBehind(Geom.Bend)].{

	## How many segments ahead of the rider a segment is, counted from the
	## rider's own at 0. A World.SegmentIndex says where a segment is in the
	## route instead.
	Position :: U32.{

		number : U32 -> SegmentPlace.Position
		number = |n| SegmentPlace.Position.(n)

		to_i64 : SegmentPlace.Position -> I64
		to_i64 = |SegmentPlace.Position.(n)| n.to_i64()

		## The rider's own segment.
		first : SegmentPlace.Position
		first = SegmentPlace.Position.(0)

		next : SegmentPlace.Position -> SegmentPlace.Position
		next = |SegmentPlace.Position.(n)| SegmentPlace.Position.(n + 1)

		## Every position in `segments_ahead`, the rider's own first.
		positions_in : List(index) -> List(SegmentPlace.Position)
		positions_in = |segments_ahead|
			List.from_iter(
				U32.until(0, segments_ahead.len().to_u32_wrap()),
			).map(SegmentPlace.Position.number)

		## The segment at this position in `segments_ahead`.
		index_in : SegmentPlace.Position, List(index) -> index
		index_in = |SegmentPlace.Position.(n), segments_ahead|
			segments_ahead.get(n.to_u64()) ?? crash "SegmentPlace.Position.index_in: past the road's end"

		## The segments of `segments_ahead` before this position, the rider's own first.
		segments_before : SegmentPlace.Position, List(index) -> List(index)
		segments_before = |SegmentPlace.Position.(n), segments_ahead|
			segments_ahead.take_first(n.to_u64())

		## Whether this position is the last one in `segments_ahead`.
		is_last_in : SegmentPlace.Position, List(index) -> Bool
		is_last_in = |SegmentPlace.Position.(n), segments_ahead|
			n.to_u64() + 1 >= segments_ahead.len()

		## Whether `segments_ahead` stops before this position.
		is_past_end_of : SegmentPlace.Position, List(index) -> Bool
		is_past_end_of = |SegmentPlace.Position.(n), segments_ahead|
			n.to_u64() >= segments_ahead.len()

		## Whether this position is among the first `count` of the road ahead.
		is_within_first : SegmentPlace.Position, U32 -> Bool
		is_within_first = |SegmentPlace.Position.(n), count| n < count

		is_eq : _
	}

	is_eq : _
}

expect SegmentPlace.Position.number(3).to_i64() == 3
expect SegmentPlace.Position.first.next().to_i64() == 1
