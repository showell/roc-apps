## What a segment's crossing does to the rider. The rider reacts only to the
## crossing on their own segment, though animations play along the chain ahead,
## and this is the one place that knows which crossings ask anything of them.
## A cat in the lane stops the rider opening the throttle, without braking, and
## draws their eye. A bird asks nothing. The pigs' gaze is no crossing, and is
## Gaze's.
import Along
import Attention
import Cat
import Speed
import World

CrossingReaction :: [].{

	## What a crossing does to the rider now: whether they may open the
	## throttle, and how hard it holds their eye.
	Reaction : { throttle : [MayAccelerate, NoAcceleration], eye_pull : Attention }

	## The reaction to `segment`'s crossing of a rider on that segment.
	reaction_to : World.Segment,
	{
		along : Along,
		speed : Speed,
		..others,
	} -> CrossingReaction.Reaction
	reaction_to = |segment, rider|
		match segment.crossing {
			CatCrosses(crossing) => {
				approach = { gap: crossing.along.distance_from(rider.along), speed: rider.speed }
				{
					throttle: if (Cat.is_in_danger(approach)) NoAcceleration else MayAccelerate,
					eye_pull: Cat.focus(approach),
				}
			}
			BirdFlies(_) | QuietRoad => { throttle: MayAccelerate, eye_pull: Attention.none }
		}
}

bird_segment : World.Segment
bird_segment = World.route_segment(0)

quiet_segment : World.Segment
quiet_segment = World.route_segment(1)

cat_segment : World.Segment
cat_segment = World.route_segment(3)

cat_along : Along
cat_along =
	match cat_segment.crossing {
		CatCrosses(crossing) => crossing.along
		BirdFlies(_) | QuietRoad => crash "CrossingReaction: segment 3 has a cat"
	}

## A rider `along` their segment at `speed` metres a step.
rider_at : Along, F64 -> { along : Along, speed : Speed }
rider_at = |along, speed| { along, speed: Speed.metres_a_step(speed) }

## The reaction to the cat of a rider `gap` metres short of it.
to_cat : F64, F64 -> CrossingReaction.Reaction
to_cat = |gap, speed| {
	along = Along.metres(cat_along.to_metres() - gap)
	CrossingReaction.reaction_to(cat_segment, rider_at(along, speed))
}

expect to_cat(42.0, 1.0).throttle == MayAccelerate
expect to_cat(41.0, 1.0).throttle == NoAcceleration
expect to_cat(22.0, 1.0).throttle == NoAcceleration
expect to_cat(3.5, 1.0).throttle == NoAcceleration
expect to_cat(3.0, 1.0).throttle == MayAccelerate
expect to_cat(2.0, 1.0).throttle == MayAccelerate
expect to_cat(22.0, 0.0).throttle == MayAccelerate

expect
	[
		(to_cat(42.0, 1.0).eye_pull.to_f64(), 0.0),
		(to_cat(41.0, 1.0).eye_pull.to_f64(), 0.0),
		(to_cat(22.0, 1.0).eye_pull.to_f64(), 0.9),
		(to_cat(3.0, 1.0).eye_pull.to_f64(), 1.8),
		(to_cat(-38.5, 1.0).eye_pull.to_f64(), 0.9),
		(to_cat(-80.0, 1.0).eye_pull.to_f64(), 0.0),
		(to_cat(22.0, 0.0).eye_pull.to_f64(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# A bird or a quiet road at each place on it, and at each speed.
expect
	[bird_segment, quiet_segment].all(
		|segment| [0.0, 60.0, 100.0, 200.0, 400.0].all(
			|along| [0.0, 0.3, 1.0].all(
				|speed| {
					rider = rider_at(Along.metres(along), speed)
					reaction = CrossingReaction.reaction_to(segment, rider)
					reaction.throttle == MayAccelerate and reaction.eye_pull == Attention.none
				},
			),
		),
	)
