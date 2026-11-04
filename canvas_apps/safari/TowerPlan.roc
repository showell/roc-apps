## TowerPlan finds the radio masts in front of the rider in a frame. A mast
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. The mast past the
## end of the segment behind the rider is seen too.
import DepthSort
import Frame
import Geom
import Scenery
import Tower
import World

TowerPlan :: [].{

	## A mast to draw: how its segment maps to the rider's view, where it
	## stands in that segment and how it is turned, how far ahead it is, and
	## where its beacon's blink starts.
	TowerItem : {
		map : Frame.Mapper,
		along : F64,
		across : F64,
		yaw : F64,
		fwd : F64,
		beacon_offset : F64,
	}

	## What the masts are seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, and the segment the rider is on.
	View : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
		rider_segment : I64,
	}

	## How far past the end of its segment a mast stands.
	tower_beyond : F64
	tower_beyond = 160.0

	## How far right of the road's edge a mast past a segment's end stands.
	tower_right : F64
	tower_right = 20.0

	## How far left of the road's edge a mast halfway along a segment stands.
	mid_tower_left : F64
	mid_tower_left = 100.0

	## How far a mast past a segment's end is turned: 30 degrees.
	tower_yaw : F64
	tower_yaw = ((30.0 * 3.14159265) / 180.0)

	## At most this many masts are drawn in a frame.
	max_vis_towers : I64
	max_vis_towers = 16

	## The masts in view: those along the chain, then the one past the end of
	## the segment behind the rider.
	in_view : TowerPlan.View -> List(TowerPlan.TowerItem)
	in_view = |view|
		if (view.rider_segment > 0) {
			List.concat(along_chain(view), tower_behind(view))
		} else {
			along_chain(view)
		}

	## The masts in view along the chain, the nearest segment's first.
	along_chain : TowerPlan.View -> List(TowerPlan.TowerItem)
	along_chain = |view| {
		places = List.from_iter(U64.until(0, view.chain.len()))
		places.join_map(|place| segment_towers(view, U64.to_i64_wrap(place)))
	}

	## The masts in view on the segment at `place` in the chain: the one past
	## its end, then the one halfway along.
	segment_towers : TowerPlan.View, I64 -> List(TowerPlan.TowerItem)
	segment_towers = |view, place| {
		seg_index = chain_segment_index(view, place)
		segment = world_segment(view, seg_index)
		end_tower = tower_if_ahead(
			view,
			{
				map: Frame.chain_map(place),
				along: (segment.length + tower_beyond),
				across: ((Scenery.lane_width / 2.0) + tower_right),
				yaw: tower_yaw,
				beacon_key: seg_index,
			},
		)
		List.concat(end_tower, mid_tower(view, place))
	}

	## The mast halfway along the segment at `place` in the chain, if it has
	## one and it is in view.
	mid_tower : TowerPlan.View, I64 -> List(TowerPlan.TowerItem)
	mid_tower = |view, place| {
		seg_index = chain_segment_index(view, place)
		segment = world_segment(view, seg_index)
		match segment.mid_tower {
			MidTower =>
				tower_if_ahead(
					view,
					{
						map: Frame.chain_map(place),
						along: (segment.length / 2.0),
						across: ((Scenery.lane_width / 2.0) - mid_tower_left),
						yaw: 0.0,
						beacon_key: (seg_index + mid_tower_beacon_step),
					},
				)
			NoMidTower => []
		}
	}

	## The mast past the end of the segment behind the rider, if it is in
	## view.
	tower_behind : TowerPlan.View -> List(TowerPlan.TowerItem)
	tower_behind = |view| {
		behind_index = (view.rider_segment - 1)
		behind = world_segment(view, behind_index)
		tower_if_ahead(
			view,
			{
				map: Frame.prev_map(behind),
				along: (behind.length + tower_beyond),
				across: ((Scenery.lane_width / 2.0) + tower_right),
				yaw: tower_yaw,
				beacon_key: behind_index,
			},
		)
	}

	## The masts as the depth sort sees them: each one's distance ahead, and
	## its place in `towers`.
	depth_keys : List(TowerPlan.TowerItem) -> List(DepthSort.DepthKey)
	depth_keys = |towers| towers.map_with_index(|tower, i| { fwd: tower.fwd, kind: KTower, i: U64.to_i64_wrap(i) })
}

## A mast halfway along a segment takes its beacon's blink from a key this
## far past its segment's, so it blinks out of step with the mast at the
## segment's end.
mid_tower_beacon_step : I64
mid_tower_beacon_step = 60

## A mast standing at `along` and `across` in the segment that `map` maps,
## if it is in front of the camera: one item, or none.
tower_if_ahead : TowerPlan.View, { map : Frame.Mapper, along : F64, across : F64, yaw : F64, beacon_key : I64 } -> List(TowerPlan.TowerItem)
tower_if_ahead = |view, { map, along, across, yaw, beacon_key }| {
	center = Frame.map_pt(view.world, view.chain, view.pose, map, along, across)
	if (center.forward <= Geom.near) {
		[]
	} else {
		[{ map, along, across, yaw, fwd: center.forward, beacon_offset: Tower.beacon_offset_for(beacon_key) }]
	}
}

chain_segment_index : TowerPlan.View, I64 -> I64
chain_segment_index = |view, place| view.chain.get(I64.to_u64_wrap(place)) ?? crash "TowerPlan: no such place in the chain"

world_segment : TowerPlan.View, I64 -> World.Segment
world_segment = |view, seg_index| view.world.get(I64.to_u64_wrap(seg_index)) ?? crash "TowerPlan: no such segment"
