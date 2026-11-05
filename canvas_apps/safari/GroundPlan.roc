## GroundPlan paints the ground under everything else in a frame: the road,
## in chunks along each segment in view; the paved corner where one segment
## bends into the next; and the pond beside a segment that ends at one.
import Frame
import Geom
import Ground
import Joint
import Num_
import Pond
import Scenery
import World
import lib.Shapes

GroundPlan :: [].{

	## The ground in view: the road, and the camera.
	View : {
		road : Frame.RoadView,
		cam_focal : F64,
	}

	## One chunk of the road along the segment at `position` in the chain,
	## which is `segment_length` long and painted in `chunk_count` chunks.
	RoadChunk : {
		position : Frame.ChainPosition,
		segment_length : F64,
		chunk_count : U32,
		chunk_number : U32,
	}

	road_color : I64
	road_color = 0x34353C

	## The road is painted in chunks no longer than this.
	road_chunk_length : F64
	road_chunk_length = 25.0

	## A bend's paving starts this far before the end of the segment that
	## bends.
	approach_length : F64
	approach_length = 40.0

	## The ground in a frame, for a rider on the segment at `rider_segment`:
	## each segment of the chain ahead in turn, then the bend from the
	## segment behind.
	draw : {
		world : List(World.Segment),
		rider_segment : World.SegmentIndex,
		pose : Frame.Pose,
		cam_focal : F64,
	} -> List(Shapes.Shape)
	draw = |
		{
			world,
			rider_segment,
			pose,
			cam_focal,
		},
	| {
		road = {
			world,
			chain: Frame.chain_ahead(world, rider_segment),
			pose,
		}
		view = {
			road,
			cam_focal,
		}
		positions = Frame.ChainPosition.all_in(road.chain)
		ahead = positions.join_map(|position| segment_ground(view, position))
		match rider_segment.previous() {
			Previous(segment_behind) => ahead.concat(ground_behind(view, segment_behind))
			AtRouteStart => ahead
		}
	}

	## How many chunks the road along a segment `length` long is painted in:
	## at least one.
	chunks_along : F64 -> U32
	chunks_along = |length| {
		chunks = Num_.ceil_real(length / GroundPlan.road_chunk_length)
		F64.to_u32_wrap(if (chunks < 1.0) 1.0 else chunks)
	}

	## The road along the segment at `position` in the chain, chunk by chunk.
	segment_road : GroundPlan.View, Frame.ChainPosition -> List(Shapes.Shape)
	segment_road = |view, position| {
		segment_length = segment_in_chain(view, position).length
		chunk_count = GroundPlan.chunks_along(segment_length)
		List.from_iter(U32.until(0, chunk_count)).join_map(
			|chunk_number| {
				corners = GroundPlan.chunk_corners(
					view,
					{
						position,
						segment_length,
						chunk_count,
						chunk_number,
					},
				)
				paint(view, { corners, color: GroundPlan.road_color })
			},
		)
	}

	## A chunk's corners: across its near end, then back across its far end.
	chunk_corners : GroundPlan.View, GroundPlan.RoadChunk -> List(Geom.RiderPoint)
	chunk_corners = |
		view,
		{
			position,
			segment_length,
			chunk_count,
			chunk_number,
		},
	| {
		near_end = segment_length * chunk_number.to_f64() / chunk_count.to_f64()
		far_end = segment_length * (chunk_number + 1).to_f64() / chunk_count.to_f64()
		corner = |along, across| Frame.rider_point_ahead(
			view.road,
			{
				position,
				along,
				across,
			},
		)
		[
			corner(near_end, 0.0),
			corner(near_end, Scenery.lane_width),
			corner(far_end, Scenery.lane_width),
			corner(far_end, 0.0),
		]
	}
}

## A patch of ground in `color`, as the view's camera sees it.
paint : GroundPlan.View, { corners : List(Geom.RiderPoint), color : I64 } -> List(Shapes.Shape)
paint = |view, { corners, color }| Ground.draw({
	corners,
	color,
	cam_focal: view.cam_focal,
})

## The segment at `position` in the chain.
segment_in_chain : GroundPlan.View, Frame.ChainPosition -> World.Segment
segment_in_chain = |view, position|
	position.index_in(view.road.chain).segment_in(view.road.world)

## The ground along the segment at `position` in the chain: its road, the
## bend into the next segment if the chain goes on, and its pond if it
## ends at one.
segment_ground : GroundPlan.View, Frame.ChainPosition -> List(Shapes.Shape)
segment_ground = |view, position| {
	segment = segment_in_chain(view, position)
	place = InChain(position)
	bend =
		if position.is_last_in(view.road.chain) {
			[]
		} else {
			bend_ground(
				view,
				Joint.bend_out_of(segment, { before: place, after: InChain(position.next()) }),
			)
		}
	List.join([
		GroundPlan.segment_road(view, position),
		bend,
		pond_ground(view, { segment, place }),
	])
}

## The bend into the rider's segment from the segment at `index`, and the
## pond that segment ends at, if it has one.
ground_behind : GroundPlan.View, World.SegmentIndex -> List(Shapes.Shape)
ground_behind = |view, index| {
	segment = index.segment_in(view.road.world)
	before = Frame.place_behind(segment)
	after = InChain(Frame.ChainPosition.first)
	List.concat(
		bend_ground(view, Joint.bend_out_of(segment, { before, after })),
		pond_ground(view, { segment, place: before }),
	)
}

## A bend's paving: the road just before it, then the corner it cuts.
bend_ground : GroundPlan.View, Joint.PlacedBend -> List(Shapes.Shape)
bend_ground = |view, bend|
	List.concat(
		paint(view, { corners: approach(view, bend), color: GroundPlan.road_color }),
		paint(view, { corners: bend_corner(view, bend), color: GroundPlan.road_color }),
	)

## The last `approach_length` of the road before a bend.
approach : GroundPlan.View, Joint.PlacedBend -> List(Geom.RiderPoint)
approach = |view, bend| {
	corner = |along, across| Frame.rider_point_at(
		view.road,
		{
			place: bend.before,
			along,
			across,
		},
	)
	start = bend.length_before - GroundPlan.approach_length
	[
		corner(bend.length_before, 0.0),
		corner(bend.length_before, Scenery.lane_width),
		corner(start, Scenery.lane_width),
		corner(start, 0.0),
	]
}

## The corner a bend cuts: from the inner edge where the segment before
## ends, to its outer edge there, out to where the two outer edges meet,
## and back to the outer edge where the segment after starts.
bend_corner : GroundPlan.View, Joint.PlacedBend -> List(Geom.RiderPoint)
bend_corner = |view, bend| {
	inner_edge = if (bend.turn.is_right()) Scenery.lane_width else 0.0
	outer_edge = Joint.outer_edge(bend.turn)
	end_at = |across| Frame.rider_point_at(
		view.road,
		{
			place: bend.before,
			along: bend.length_before,
			across,
		},
	)
	[
		end_at(inner_edge),
		end_at(outer_edge),
		Joint.joint_apex(view.road, bend),
		Frame.rider_point_at(
			view.road,
			{
				place: bend.after,
				along: 0.0,
				across: outer_edge,
			},
		),
	]
}

## The pond past the end of `segment`, which lies at `place`: its water, then
## its bank. A segment that ends at no pond has none.
pond_ground : GroundPlan.View,
{
	segment : World.Segment,
	place : Frame.SegmentPlace,
} -> List(Shapes.Shape)
pond_ground = |view, { segment, place }|
	if Scenery.is_pond(segment.exit_creature) {
		on_map = |outline|
			outline.map(
				|point| Frame.rider_point_at(
					view.road,
					{
						place,
						along: segment.length + point.along,
						across: point.across,
					},
				),
			)
		List.concat(
			paint(view, { corners: on_map(Pond.water_outline), color: Pond.water_color }),
			paint(view, { corners: on_map(Pond.bank), color: Pond.bank_color }),
		)
	} else {
		[]
	}
