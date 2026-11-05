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
		place : Frame.SegmentPlace,
		along : F64,
		across : F64,
		yaw : F64,
		forward : F64,
		beacon_offset : F64,
	}

	## What the masts are seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, and the segment the rider is on.
	View : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
		pose : Frame.Pose,
		rider_segment : World.SegmentIndex,
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
		match view.rider_segment.previous() {
			Previous(segment_behind) => List.concat(
				along_chain(view),
				tower_behind(view, segment_behind),
			)
			AtRouteStart => along_chain(view)
		}

	## The masts in view along the chain, the nearest segment's first.
	along_chain : TowerPlan.View -> List(TowerPlan.TowerItem)
	along_chain = |view| {
		positions = Frame.ChainPosition.all_in(view.chain)
		positions.join_map(|position| segment_towers(view, position))
	}

	## The masts in view on the segment at `position` in the chain: the one past
	## its end, then the one halfway along.
	segment_towers : TowerPlan.View, Frame.ChainPosition -> List(TowerPlan.TowerItem)
	segment_towers = |view, position| {
		index = position.index_in(view.chain)
		segment = index.segment_in(view.world)
		end_tower = tower_if_ahead(
			view,
			{
				place: InChain(position),
				along: (segment.length + tower_beyond),
				across: ((Scenery.lane_width / 2.0) + tower_right),
				yaw: tower_yaw,
				beacon_key: index.to_i64(),
			},
		)
		List.concat(end_tower, mid_tower(view, position))
	}

	## The mast halfway along the segment at `position` in the chain, if it has
	## one and it is in view.
	mid_tower : TowerPlan.View, Frame.ChainPosition -> List(TowerPlan.TowerItem)
	mid_tower = |view, position| {
		index = position.index_in(view.chain)
		segment = index.segment_in(view.world)
		match segment.mid_tower {
			MidTower =>
				tower_if_ahead(
					view,
					{
						place: InChain(position),
						along: (segment.length / 2.0),
						across: ((Scenery.lane_width / 2.0) - mid_tower_left),
						yaw: 0.0,
						beacon_key: index.to_i64() + mid_tower_beacon_step,
					},
				)
			NoMidTower => []
		}
	}

	## The mast past the end of the segment at `index`, the one behind the
	## rider, if it is in view.
	tower_behind : TowerPlan.View, World.SegmentIndex -> List(TowerPlan.TowerItem)
	tower_behind = |view, index| {
		behind = index.segment_in(view.world)
		tower_if_ahead(
			view,
			{
				place: Frame.place_behind(behind),
				along: (behind.length + tower_beyond),
				across: ((Scenery.lane_width / 2.0) + tower_right),
				yaw: tower_yaw,
				beacon_key: index.to_i64(),
			},
		)
	}

	## The masts as the depth sort sees them: each one's distance ahead, and
	## its position in `towers`.
	depth_keys : List(TowerPlan.TowerItem) -> List(DepthSort.DepthKey)
	depth_keys = |towers| towers.map_with_index(
		|tower, i| {
			forward: tower.forward,
			subject: Tower(i.to_u32_wrap()),
		},
	)
}

## A mast halfway along a segment takes its beacon's blink from a key this
## far past its segment's, so it blinks out of step with the mast at the
## segment's end.
mid_tower_beacon_step : I64
mid_tower_beacon_step = 60

## A mast standing at `along` and `across` in the segment that `place` maps,
## if it is in front of the camera: one item, or none.
tower_if_ahead : TowerPlan.View,
{
	place : Frame.SegmentPlace,
	along : F64,
	across : F64,
	yaw : F64,
	beacon_key : I64,
} -> List(TowerPlan.TowerItem)
tower_if_ahead = |
	view,
	{
		place,
		along,
		across,
		yaw,
		beacon_key,
	},
| {
	center = Frame.rider_point_at(
		{
			world: view.world,
			chain: view.chain,
			pose: view.pose,
		},
		{
			place: place,
			along,
			across,
		},
	)
	if center.forward <= Geom.near_plane {
		[]
	} else {
		[
			{
				place,
				along,
				across,
				yaw,
				forward: center.forward,
				beacon_offset: Tower.beacon_offset_for(beacon_key),
			},
		]
	}
}
