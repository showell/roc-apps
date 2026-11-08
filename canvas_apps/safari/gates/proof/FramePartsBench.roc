## FramePartsBench times one part of a frame's computation at a time. It rides
## to step `from`, then works out `part` at every step from `from` to `to`,
## `reps` times over, and prints a sum of what the part made so nothing is left
## unused. The bench's platform has no clock, so a caller times whole runs and
## subtracts the run of part `none`, which only rides. Part `counts` prints the
## shapes and polygon points of each kind at each step instead.
##
##   roc build --opt=speed FramePartsBench.roc --output=<bin>; <bin> trees 0 0 200
app [main!] { game: "../../game.roc", lib: "../../../lib/main.roc" }

import game.Distance
import game.FrameView
import game.EncounterPoses
import game.EncounterSighting
import game.GuardRail
import game.Pipeline
import game.RailSighting
import game.Rendered
import game.RideInstant
import game.RiderCamera
import game.RoadAhead
import game.Route
import game.SafariApp
import game.Scene
import game.Sky
import game.Sun
import game.Grass
import game.TowerSighting
import game.TreeSighting
import game.BillboardSighting
import game.TruckSighting
import game.World
import lib.Shapes

main! = |args| {
	part = args.get(0) ?? crash "FramePartsBench: give a part, then the steps from and to, then the reps"
	from = number_arg(args, 1)
	to = number_arg(args, 2)
	reps = number_arg(args, 3)
	route = World.route
	var $instant = RideInstant.initial
	for _ in 0..<from {
		$instant = step_on(route, $instant)
	}
	var $sum = 0
	var $report = ""
	for _ in from..=to {
		if part == "counts" {
			$report = $report.concat(counts_line(route, $instant))
		} else if part == "sort_only" or part == "flatten_only" or part == "frame_only" {
			$sum = $sum + prepared_size(part, { route, instant: $instant, reps })
		} else {
			for _ in 0..<reps {
				$sum = $sum + part_size(part, { route, instant: $instant })
			}
		}
		$instant = step_on(route, $instant)
	}
	echo!("${$report}${part} ${from.to_str()}..${to.to_str()} x${reps.to_str()}: ${$sum.to_str()}\n")
	Ok({})
}

number_arg : List(Str), U64 -> U64
number_arg = |args, at| {
	text = args.get(at) ?? crash "FramePartsBench: argument ${at.to_str()} is missing"
	U64.from_str(text) ?? crash "FramePartsBench: argument ${at.to_str()} must be a whole number"
}

step_on : Route, RideInstant -> RideInstant
step_on = |route, instant|
	match RideInstant.next_or_restart(route, instant) {
		Continued(next) | Restarted(next) => next
	}

## What one part makes at `instant`, as a number: shapes, renderings or sightings.
part_size : Str, { route : Route, instant : RideInstant } -> U64
part_size = |part, { route, instant }| {
	if part == "none" {
		0
	} else if part == "full" {
		view = FrameView.frame_view_at(route, instant)
		view.framed_shapes(SafariApp.lean_space(view.roll)).len()
	} else if part == "view" {
		FrameView.frame_view_at(route, instant).ride_shape_lists.join().len()
	} else if part == "camera" {
		FrameView.camera_at(route, instant).cam_focal.to_f64().to_u64_try() ?? crash "FramePartsBench: a focal length is a finite number"
	} else {
		camera = FrameView.camera_at(route, instant)
		if part == "sky" {
			sky = Sky.colors_at(instant.clock)
			sun = Sun.sighting(camera, instant.clock)
			[[Sky.sky_shape(sky)], Sun.sun_shapes(sun), [Grass.grass_shape]].join().len()
		} else if part == "skyline" {
			FrameView.skyline_shapes(camera, instant.clock).len()
		} else {
			road = RoadAhead.RoadView.ahead_of(route, camera.route_place.segment_index)
			if part == "road" {
				RoadAhead.segments_in_view(road).len()
			} else if part == "ground" {
				FrameView.ground_shapes(road, camera).len()
			} else {
				kind_size(part, { road, camera, instant })
			}
		}
	}
}

## What one kind beside the road makes: the sightings alone for a `_sight` part,
## the renderings for a kind's own name, and Scene's whole work for `scene`.
kind_size : Str,
{
	road : RoadAhead.RoadView,
	camera : RiderCamera,
	instant : RideInstant,
} -> U64
kind_size = |part, { road, camera, instant }| {
	cam = { vantage: RiderCamera.vantage(camera), cam_focal: camera.cam_focal }
	cam_focal = cam.cam_focal
	facts = FrameView.ride_facts(instant)
	if part == "scene" {
		Scene.scene_shapes(Scene.scene_in_view(road, { camera: cam, facts })).len()
	} else if part == "scene_in_view" {
		scene_rendering_count(Scene.scene_in_view(road, { camera: cam, facts }))
	} else if part == "trees_sight" {
		TreeSighting.trees_in_view(road, cam).len()
	} else if part == "trees" {
		shape_count(Scene.tree_renderings(TreeSighting.trees_in_view(road, cam), cam_focal))
	} else if part == "towers_sight" {
		TowerSighting.towers_in_view(road, { camera: cam, clock: facts.clock }).len()
	} else if part == "towers" {
		on_road = { road, vantage: cam.vantage }
		shape_count(
			TowerSighting.towers_in_view(road, { camera: cam, clock: facts.clock }).map(
				|tower| Pipeline.rendering_of(tower, { cam_focal, context: on_road }),
			),
		)
	} else if part == "billboards_sight" {
		BillboardSighting.billboards_in_view(road, cam).len()
	} else if part == "billboards" {
		shape_count(
			BillboardSighting.billboards_in_view(road, cam).map(
				|billboard| Pipeline.rendering_of(billboard, { cam_focal, context: {} }),
			),
		)
	} else if part == "cats" {
		cats = EncounterPoses.cat_poses(road, facts.encounter_timing)
		shape_count(
			EncounterSighting.animals_in_view(road, { camera: cam, animals: cats }).map(
				|cat| Pipeline.rendering_of(cat, { cam_focal, context: {} }),
			),
		)
	} else if part == "birds" {
		birds = EncounterPoses.bird_poses(road, facts.encounter_timing)
		shape_count(
			EncounterSighting.animals_in_view(road, { camera: cam, animals: birds }).map(
				|bird| Pipeline.rendering_of(bird, { cam_focal, context: {} }),
			),
		)
	} else if part == "truck" {
		shape_count(truck_renderings(road, { cam, facts }))
	} else if part == "rails" {
		shape_count(
			RailSighting.rail_quads_in_view(road, cam).keep_oks(
				|quad| GuardRail.quad_rendering(quad, cam_focal),
			),
		)
	} else {
		crash "FramePartsBench: no part ${part}"
	}
}

## A last step of the frame alone, `reps` times over what comes before it,
## which is worked out once: the depth sort of the scene's renderings, the
## sorted pictures joined into one list of shapes, or the whole frame's shapes
## put together from a frame view (the backdrop joined to the ride's shapes,
## in the leaning space).
prepared_size : Str,
{
	route : Route,
	instant : RideInstant,
	reps : U64,
} -> U64
prepared_size = |part, { route, instant, reps }| {
	camera = FrameView.camera_at(route, instant)
	road = RoadAhead.RoadView.ahead_of(route, camera.route_place.segment_index)
	cam = { vantage: RiderCamera.vantage(camera), cam_focal: camera.cam_focal }
	scene = Scene.scene_in_view(road, { camera: cam, facts: FrameView.ride_facts(instant) })
	view = FrameView.frame_view_at(route, instant)
	sorted = Scene.scene_renderings(scene)
	var $sum = 0
	for _ in 0..<reps {
		$sum = $sum
			+ (
				if part == "sort_only" {
					Scene.scene_renderings(scene).len()
				} else if part == "flatten_only" {
					sorted.join_map(|rendering| rendering.picture().to_shapes()).len()
				} else {
					view.framed_shapes(SafariApp.lean_space(view.roll)).len()
				}
			)
	}
	$sum
}

truck_renderings : RoadAhead.RoadView,
{
	cam : { vantage : _, cam_focal : _ },
	facts : Scene.RideFacts,
} -> List(Rendered)
truck_renderings = |road, { cam, facts }| {
	on_road = { road, vantage: cam.vantage }
	match TruckSighting.truck_in_view(
		road,
		{
			camera: cam,
			route_position: facts.truck.route_position,
			lit_truck: facts.truck.lit_truck,
		},
	) {
		Ok(truck) => [Pipeline.rendering_of(truck, { cam_focal: cam.cam_focal, context: on_road })]
		Err(NoTruck) | Err(BehindCamera) => []
	}
}

scene_rendering_count : Scene -> U64
scene_rendering_count = |scene|
	[
		scene.trees.len(),
		scene.birds.len(),
		scene.towers.len(),
		scene.billboards.len(),
		scene.cats.len(),
		scene.trucks.len(),
		scene.rails.len(),
	].sum()

shape_count : List(Rendered) -> U64
shape_count = |renderings| renderings.map(|r| r.picture().to_shapes().len()).sum()

## The polygon points in `shapes`.
point_count : List(Shapes.Shape) -> U64
point_count = |shapes|
	shapes.map(
		|shape|
			match shape {
				Poly({ coordinates, fill: _ }) => coordinates.len() // 2
				_ => 0
			},
	).sum()

## One line per kind at `instant`: renderings, shapes and polygon points.
counts_line : Route, RideInstant -> Str
counts_line = |route, instant| {
	camera = FrameView.camera_at(route, instant)
	road = RoadAhead.RoadView.ahead_of(route, camera.route_place.segment_index)
	cam = { vantage: RiderCamera.vantage(camera), cam_focal: camera.cam_focal }
	scene = Scene.scene_in_view(road, { camera: cam, facts: FrameView.ride_facts(instant) })
	kinds = [
		("trees", scene.trees),
		("birds", scene.birds),
		("towers", scene.towers),
		("billboards", scene.billboards),
		("cats", scene.cats),
		("truck", scene.trucks),
		("rails", scene.rails),
	]
	skyline = FrameView.skyline_shapes(camera, instant.clock)
	ground = FrameView.ground_shapes(road, camera)
	step = instant.clock.to_str()
	sighted = TreeSighting.trees_in_view(road, cam)
	coned = sighted.count_if(|tree| tree.spot.foot().forward() < Distance.metres(200.0))
	var $text = ""
	for (name, renderings) in kinds {
		shapes = renderings.join_map(|r| r.picture().to_shapes())
		things = renderings.len().to_str()
		points = point_count(shapes).to_str()
		$text = $text.concat("${step} ${name}: ${things} things, ${shapes.len().to_str()} shapes, ${points} points\n")
	}
	$text
		.concat("${step} skyline: ${skyline.len().to_str()} shapes, ${point_count(skyline).to_str()} points\n")
		.concat("${step} ground: ${ground.len().to_str()} shapes, ${point_count(ground).to_str()} points\n")
		.concat("${step} segments in view: ${RoadAhead.segments_in_view(road).len().to_str()}\n")
		.concat("${step} trees in sight: ${sighted.len().to_str()}, within 200 m (cones): ${coned.to_str()}\n")
}
