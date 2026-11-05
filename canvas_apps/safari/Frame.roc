# Frame -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Geom
import Scenery
import World

Frame :: [].{
	Pose : Geom.Pose

	## The road in view: the world's segments, the chain of them ahead of
	## the rider, and the rider's pose.
	RoadView : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
	}

	Mapper : {
		is_chain : Bool,
		d : I64,
		prev_len : F64,
		prev_angle : F64,
		prev_side : Geom.TurnSide,
		prev_w : F64,
	}

	look_ahead : I64
	look_ahead = 7

	max_chain : I64
	max_chain = 8

	build_chain : List(World.Segment), I64 -> List(I64)
	build_chain = |segs, start| chain_onto(
		segs,
		{
			segment_at: start,
			chain_length: 0,
			chain: [],
		},
	)

	# An accumulator loop: linear, where appending a recursive call is quadratic.
	chain_onto : List(World.Segment),
	{
		segment_at : I64,
		chain_length : I64,
		chain : List(I64),
	} -> List(I64)
	chain_onto = |
		segs,
		{
			segment_at: s,
			chain_length: n,
			chain: acc,
		},
	| (
		if n >= look_ahead {
			acc
		} else {
			(
				if n >= max_chain {
					acc
				} else {
					match (
						List.get(
							segs,
							I64.to_u64_wrap(s),
						) ?? crash ("list-at out of range")
					).ending {
						Continues({ next }) => chain_onto(
							segs,
							{
								segment_at: next,
								chain_length: (n + 1),
								chain: List.append(acc, s),
							},
						)
						Terminates => List.append(acc, s)
					}
				}
			)
		}
	)

	compose_down : Geom.RoadPoint,
	{
		world : List(World.Segment),
		chain : List(I64),
		segments_ahead : I64,
	} -> Geom.RoadPoint
	compose_down = |
		point,
		{
			world: segs,
			chain: ch,
			segments_ahead: k,
		},
	| (
		if k <= 0 {
			point
		} else {
			(
				{
					chosen = List.get(
						ch,
						I64.to_u64_wrap(k - 1),
					) ?? crash "Frame.compose_down: the chain has a segment at each step"
					seg = List.get(
						segs,
						I64.to_u64_wrap(chosen),
					) ?? crash "Frame.compose_down: the chain names a segment of the world"
					p = Geom.in_segment_before(
						point,
						{
							segment_length: seg.length,
							turn_angle: seg.exit_angle,
							turn_side: seg.exit_side,
							lane_width: Scenery.lane_width,
						},
					)
					compose_down(
						p,
						{
							world: segs,
							chain: ch,
							segments_ahead: (k - 1),
						},
					)
				}
			)
		}
	)

	at : Frame.RoadView,
	{
		segments_ahead : I64,
		along : F64,
		across : F64,
	} -> Geom.RiderPoint
	at = |
		road,
		{
			segments_ahead,
			along,
			across,
		},
	|
		Geom.to_rider_point(
			compose_down(
				{ along, across },
				{
					world: road.world,
					chain: road.chain,
					segments_ahead,
				},
			),
			road.pose,
		)

	chain_map : I64 -> Frame.Mapper
	chain_map = |d| {
		is_chain: True,
		d: d,
		prev_len: 0.0,
		prev_angle: 0.0,
		prev_side: TurnsLeft,
		prev_w: 0.0,
	}

	prev_map : World.Segment -> Frame.Mapper
	prev_map = |s| {
		is_chain: False,
		d: 0,
		prev_len: s.length,
		prev_angle: s.exit_angle,
		prev_side: s.exit_side,
		prev_w: Scenery.lane_width,
	}

	map_pt : Frame.RoadView,
	{
		mapper : Frame.Mapper,
		along : F64,
		across : F64,
	} -> Geom.RiderPoint
	map_pt = |
		road,
		{
			mapper: m,
			along,
			across,
		},
	| (
		if m.is_chain {
			at(
				road,
				{
					segments_ahead: m.d,
					along,
					across,
				},
			)
		} else {
			Geom.to_rider_point(
				Geom.in_segment_after(
					{ along, across },
					{
						segment_length: m.prev_len,
						turn_angle: m.prev_angle,
						turn_side: m.prev_side,
						lane_width: m.prev_w,
					},
				),
				road.pose,
			)
		}
	)
}
