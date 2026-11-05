## TowerSighting finds the radio masts in front of the rider in a frame. A mast
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. The mast past the
## end of the segment behind the rider is seen too. Each mast's beacon blinks
## on the ride's clock, and the sighting says how bright it is in the frame.
import Across
import Along
import Angle
import Clock
import DepthSort
import Distance
import Fraction
import Frame
import Geom
import Scenery
import Steps
import lib.Trig
import World

TowerSighting :: [].{

	## A mast to draw: how its segment maps to the rider's view, where it
	## stands in that segment and how it is turned, how far ahead it is, and
	## how bright its beacon is.
	TowerItem : {
		place : Frame.SegmentPlace,
		along : Along,
		across : Across,
		yaw : Angle.Turn,
		forward : F64,
		beacon_brightness : Fraction,
	}

	## What the masts are seen from: the road in view, and the ride's clock.
	View : { road : Frame.RoadView, clock : Clock }

	## How far past the end of its segment a mast stands.
	tower_beyond : Distance
	tower_beyond = Distance.metres(160.0)

	## How far right of the road's edge a mast past a segment's end stands.
	tower_right : Distance
	tower_right = Distance.metres(20.0)

	## How far left of the road's edge a mast halfway along a segment stands.
	mid_tower_left : Distance
	mid_tower_left = Distance.metres(100.0)

	## How far a mast past a segment's end is turned: 30 degrees.
	tower_yaw : Angle.Turn
	tower_yaw = Angle.Turn.radians((30.0 * 3.14159265) / 180.0)

	## At most this many masts are drawn in a frame.
	max_vis_towers : I64
	max_vis_towers = 16

	## A beacon blinks once in this many steps of the ride.
	beacon_period : Steps
	beacon_period = Steps.of(120)

	## Each mast's blink starts this many steps past the last one's, a number
	## that shares no factor with the period, so neighbours blink apart.
	beacon_stagger : Steps
	beacon_stagger = Steps.of(37)

	## How far into its blink the mast with key `n` is when the ride's clock
	## is 0.
	beacon_offset_for : U32 -> Steps
	beacon_offset_for = |n| beacon_stagger.times(n).wrapped_to(beacon_period)

	## How bright a beacon is `phase` steps into its blink.
	beacon_brightness : Steps -> Fraction
	beacon_brightness = |phase| {
		wrapped = phase.wrapped_to(beacon_period).to_f64()
		angle = (((2.0 * Trig.pi) * wrapped) / beacon_period.to_f64())
		Fraction.of(((1.0 - Trig.r_cos(angle)) / 2.0))
	}

	## The masts in view: those along the chain, then the one past the end of
	## the segment behind the rider.
	in_view : TowerSighting.View -> List(TowerSighting.TowerItem)
	in_view = |view|
		match Frame.segment_behind(view.road) {
			Previous(segment_behind) => along_chain(view).concat(tower_behind(view, segment_behind))
			AtRouteStart => along_chain(view)
		}

	## The masts in view along the chain, the nearest segment's first.
	along_chain : TowerSighting.View -> List(TowerSighting.TowerItem)
	along_chain = |view| {
		positions = Frame.ChainPosition.all_in(view.road.chain)
		positions.join_map(|position| segment_towers(view, position))
	}

	## The masts in view on the segment at `position` in the chain: the one past
	## its end, then the one halfway along.
	segment_towers : TowerSighting.View, Frame.ChainPosition -> List(TowerSighting.TowerItem)
	segment_towers = |view, position| {
		index = position.index_in(view.road.chain)
		segment = index.segment_in(view.road.world)
		end_tower = tower_if_ahead(
			view,
			{
				place: InChain(position),
				along: Along.at(segment.length.plus(tower_beyond)),
				across: Scenery.from_left_edge(Across.right_of_middle(tower_right)),
				yaw: tower_yaw,
				beacon_key: index.to_u32(),
			},
		)
		end_tower.concat(mid_tower(view, position))
	}

	## The mast halfway along the segment at `position` in the chain, if it has
	## one and it is in view.
	mid_tower : TowerSighting.View, Frame.ChainPosition -> List(TowerSighting.TowerItem)
	mid_tower = |view, position| {
		index = position.index_in(view.road.chain)
		segment = index.segment_in(view.road.world)
		match segment.mid_tower {
			MidTower =>
				tower_if_ahead(
					view,
					{
						place: InChain(position),
						along: Along.at(segment.length.divided_by(2.0)),
						across: Scenery.from_left_edge(Across.left_of_middle(mid_tower_left)),
						yaw: Angle.straight_ahead,
						beacon_key: index.to_u32() + mid_tower_beacon_step,
					},
				)
			NoMidTower => []
		}
	}

	## The mast past the end of the segment at `index`, the one behind the
	## rider, if it is in view.
	tower_behind : TowerSighting.View, World.SegmentIndex -> List(TowerSighting.TowerItem)
	tower_behind = |view, index| {
		behind = index.segment_in(view.road.world)
		tower_if_ahead(
			view,
			{
				place: Frame.place_behind(behind),
				along: Along.at(behind.length.plus(tower_beyond)),
				across: Scenery.from_left_edge(Across.right_of_middle(tower_right)),
				yaw: tower_yaw,
				beacon_key: index.to_u32(),
			},
		)
	}

	## The masts as the depth sort sees them: each one's distance ahead, and
	## its position in `towers`.
	depth_keys : List(TowerSighting.TowerItem) -> List(DepthSort.DepthKey)
	depth_keys = |towers| towers.map_with_index(
		|tower, i| {
			forward: tower.forward,
			subject: Tower(i.to_u32_wrap()),
		},
	)
}

## A mast halfway along a segment takes its beacon's blink from a key this
## far past its segment's. That many staggers come to half a period past a
## whole number of periods, so it blinks exactly opposite the mast at the
## segment's end.
mid_tower_beacon_step : U32
mid_tower_beacon_step = 60

## A mast standing at `along` and `across` in the segment that `place` maps,
## if it is in front of the camera: one item, or none.
tower_if_ahead : TowerSighting.View,
{
	place : Frame.SegmentPlace,
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	beacon_key : U32,
} -> List(TowerSighting.TowerItem)
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
		view.road,
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
				beacon_brightness: TowerSighting.beacon_brightness(
					view.clock.minus(Clock.start).plus(TowerSighting.beacon_offset_for(beacon_key)),
				),
			},
		]
	}
}
