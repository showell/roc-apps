## GroundPlan paints the ground under everything else in a frame: the road,
## in chunks along each segment in view; the paved corner where one segment
## bends into the next; and the pond beside a segment that ends at one.
import Frame
import Geom
import Ground
import Joint
import Num_
import Paint
import Pond
import Scenery
import World

GroundPlan :: [].{

	## The ground in view: the world's segments, the chain of them ahead of
	## the rider, the rider's pose, and the camera.
	View : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
		cam_focal : F64,
		view_w : F64,
	}

	road_color : I64
	road_color = 0x34353C

	## The road is painted in chunks no longer than this.
	road_chunk : F64
	road_chunk = 25.0

	## A bend's paving starts this far before the end of the segment that
	## bends.
	approach_length : F64
	approach_length = 40.0

	## The ground in a frame, for a rider on segment `segment` of the world:
	## each segment of the chain ahead in turn, then the bend from the
	## segment behind.
	draw : {
		world : List(World.Segment),
		segment : I64,
		pose : Frame.Pose,
		cam_focal : F64,
		view_w : F64,
	} -> List(Paint.DrawCmd)
	draw = |{ world, segment, pose, cam_focal, view_w }| {
		view = { world, chain: Frame.build_chain(world, segment), pose, cam_focal, view_w }
		positions = List.from_iter(I64.until(0, view.chain.len().to_i64_wrap()))
		ahead = positions.join_map(|position| segment_ground(view, position))
		if (segment > 0) {
			ahead.concat(ground_behind(view, (segment - 1)))
		} else {
			ahead
		}
	}

	## How many chunks the road along a segment `length` long is painted in:
	## at least one.
	chunk_count : F64 -> I64
	chunk_count = |length| {
		chunks = Num_.ceil_real((length / GroundPlan.road_chunk))
		F64.to_i64_wrap(if (chunks < 1.0) 1.0 else chunks)
	}

	## The road along the segment at `position` in the chain, chunk by chunk.
	segment_road : GroundPlan.View, I64 -> List(Paint.DrawCmd)
	segment_road = |view, position| {
		length = segment_in_chain(view, position).length
		chunks = GroundPlan.chunk_count(length)
		List.from_iter(I64.until(0, chunks)).join_map(
			|chunk| {
				corners = GroundPlan.chunk_corners(view, { position, length, chunks, chunk })
				paint(view, { corners, color: GroundPlan.road_color })
			},
		)
	}

	## Chunk `chunk` of the road along the segment at `position` in the
	## chain, which is `length` long and painted in `chunks` chunks.
	RoadChunk : {
		position : I64,
		length : F64,
		chunks : I64,
		chunk : I64,
	}

	## A chunk's corners: across its near end, then back across its far end.
	chunk_corners : GroundPlan.View, GroundPlan.RoadChunk -> List(Geom.RiderPt)
	chunk_corners = |view, { position, length, chunks, chunk }| {
		near_end = ((length * chunk.to_f64()) / chunks.to_f64())
		far_end = ((length * (chunk + 1).to_f64()) / chunks.to_f64())
		at = |along, across| Frame.at(view.world, view.chain, view.pose, position, along, across)
		[
			at(near_end, 0.0),
			at(near_end, Scenery.lane_width),
			at(far_end, Scenery.lane_width),
			at(far_end, 0.0),
		]
	}
}

## A turn from one segment into the next: where each segment is on the
## map, how long the one before is, and which way the road turns.
Bend : {
	before : Frame.Mapper,
	after : Frame.Mapper,
	length_before : F64,
	exit_right : Bool,
}

## A patch of ground in `color`, as the view's camera sees it.
paint : GroundPlan.View, { corners : List(Geom.RiderPt), color : I64 } -> List(Paint.DrawCmd)
paint = |view, { corners, color }| Ground.draw({ corners, color, cam_focal: view.cam_focal, view_w: view.view_w })

## The segment at `position` in the chain.
segment_in_chain : GroundPlan.View, I64 -> World.Segment
segment_in_chain = |view, position| {
	index = view.chain.get(position.to_u64_wrap()) ?? crash "GroundPlan: a position past the chain's end"
	view.world.get(index.to_u64_wrap()) ?? crash "GroundPlan: a chain names a segment the world lacks"
}

## The ground along the segment at `position` in the chain: its road, the
## bend into the next segment if the chain goes on, and its pond if it
## ends at one.
segment_ground : GroundPlan.View, I64 -> List(Paint.DrawCmd)
segment_ground = |view, position| {
	segment = segment_in_chain(view, position)
	bend =
		if ((position + 1) >= view.chain.len().to_i64_wrap()) {
			[]
		} else {
			bend_ground(view, bend_out_of(segment, { before: Frame.chain_map(position), after: Frame.chain_map((position + 1)) }))
		}
	List.join([
		GroundPlan.segment_road(view, position),
		bend,
		pond_ground(view, { segment, place: Frame.chain_map(position) }),
	])
}

## The bend into the rider's segment from world segment `index`, and the
## pond that segment ends at, if it has one.
ground_behind : GroundPlan.View, I64 -> List(Paint.DrawCmd)
ground_behind = |view, index| {
	segment = view.world.get(index.to_u64_wrap()) ?? crash "GroundPlan: the segment behind the rider is past the world's end"
	before = Frame.prev_map(segment)
	List.concat(
		bend_ground(view, bend_out_of(segment, { before, after: Frame.chain_map(0) })),
		pond_ground(view, { segment, place: before }),
	)
}

## The bend at the end of `segment`, which is on the map as `before`.
bend_out_of : World.Segment, { before : Frame.Mapper, after : Frame.Mapper } -> Bend
bend_out_of = |segment, { before, after }| { before, after, length_before: segment.length, exit_right: segment.exit_right }

## A bend's paving: the road just before it, then the corner it cuts.
bend_ground : GroundPlan.View, Bend -> List(Paint.DrawCmd)
bend_ground = |view, bend|
	List.concat(
		paint(view, { corners: approach(view, bend), color: GroundPlan.road_color }),
		paint(view, { corners: bend_corner(view, bend), color: GroundPlan.road_color }),
	)

## The last `approach_length` of the road before a bend.
approach : GroundPlan.View, Bend -> List(Geom.RiderPt)
approach = |view, bend| {
	before = |along, across| Frame.map_pt(view.world, view.chain, view.pose, bend.before, along, across)
	start = (bend.length_before - GroundPlan.approach_length)
	[
		before(bend.length_before, 0.0),
		before(bend.length_before, Scenery.lane_width),
		before(start, Scenery.lane_width),
		before(start, 0.0),
	]
}

## The corner a bend cuts: from the inner edge where the segment before
## ends, to its outer edge there, out to where the two outer edges meet,
## and back to the outer edge where the segment after starts.
bend_corner : GroundPlan.View, Bend -> List(Geom.RiderPt)
bend_corner = |view, bend| {
	before = |along, across| Frame.map_pt(view.world, view.chain, view.pose, bend.before, along, across)
	after = |along, across| Frame.map_pt(view.world, view.chain, view.pose, bend.after, along, across)
	inner_edge = if bend.exit_right Scenery.lane_width else 0.0
	outer_edge = Joint.outer_cu(bend.exit_right)
	apex = Joint.joint_apex(
		view.world,
		view.chain,
		view.pose,
		bend.before,
		bend.after,
		bend.length_before,
		bend.exit_right,
	)
	[
		before(bend.length_before, inner_edge),
		before(bend.length_before, outer_edge),
		apex,
		after(0.0, outer_edge),
	]
}

## The pond past the end of `segment`, which is on the map at `place`:
## its water, then its bank. A segment that ends at no pond has none.
pond_ground : GroundPlan.View, { segment : World.Segment, place : Frame.Mapper } -> List(Paint.DrawCmd)
pond_ground = |view, { segment, place }|
	if Scenery.is_pond(segment.exit_creature) {
		on_map = |outline|
			outline.map(|point| Frame.map_pt(view.world, view.chain, view.pose, place, (segment.length + point.along), point.across))
		List.concat(
			paint(view, { corners: on_map(Pond.water_outline), color: Pond.water_color }),
			paint(view, { corners: on_map(Pond.bank), color: Pond.bank_color }),
		)
	} else {
		[]
	}
