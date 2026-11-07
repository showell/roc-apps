## Scene gathers what one frame shows beside the road: the trees, towers,
## billboards, cats, guard rails, the truck and the birds in view, each found by
## its own sighting and rendered as soon as it is found. Past the sighting
## nothing asks what kind a thing is, so each field holds only renderings.
import Clock
import Conifer
import Distance
import EncounterSighting
import BillboardSighting
import Geom
import RoadAhead
import GuardRail
import Pipeline
import Pixels
import RailSighting
import Rendered
import TowerSighting
import TreeSighting
import LitTruck
import TruckSighting
import Speed
import lib.Shapes

## The things in view, rendered, one field for each sighting that found them.
Scene := {
	trees : List(Rendered),
	birds : List(Rendered),
	towers : List(Rendered),
	billboards : List(Rendered),
	cats : List(Rendered),
	truck : Try(Rendered, [NoTruck, BehindCamera]),
	rails : List(Rendered),
}.{

	## What the sightings read beyond the road: the rider's speed, where the
	## truck is and how it looks, and the clock.
	RideFacts : {
		speed : Speed,
		truck : { route_position : Distance, lit_truck : LitTruck },
		clock : Clock,
	}

	## Everything `camera` sees of `road`, each thing rendered as it is sighted.
	scene_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		facts : Scene.RideFacts,
	} -> Scene
	scene_in_view = |road, { camera, facts }| {
		cam_focal = camera.cam_focal
		on_road = { road, vantage: camera.vantage }
		truck_at = TruckSighting.truck_in_view(
			road,
			{
				camera,
				route_position: facts.truck.route_position,
				lit_truck: facts.truck.lit_truck,
			},
		)
		{
			trees: Scene.tree_renderings(TreeSighting.trees_in_view(road, camera), cam_focal),
			birds: EncounterSighting.birds_in_view(road, camera).map(
				|bird| Pipeline.rendering_of(bird, { cam_focal, context: {} }),
			),
			towers: TowerSighting.towers_in_view(road, { camera, clock: facts.clock }).map(
				|tower| Pipeline.rendering_of(tower, { cam_focal, context: on_road }),
			),
			billboards: BillboardSighting.billboards_in_view(road, camera).map(
				|billboard| Pipeline.rendering_of(billboard, { cam_focal, context: {} }),
			),
			cats: EncounterSighting.cats_in_view(road, { camera, speed: facts.speed }).map(
				|cat| Pipeline.rendering_of(cat, { cam_focal, context: {} }),
			),
			truck: truck_at.map_ok(
				|truck| Pipeline.rendering_of(truck, { cam_focal, context: on_road }),
			),
			rails: RailSighting.rail_quads_in_view(road, camera).keep_oks(
				|quad| GuardRail.quad_rendering(quad, cam_focal),
			),
		}
	}

	## The scene's renderings far to near. Two about as far away as each other
	## keep the order of the fields they come from, so that order decides which
	## of two tied things is drawn over the other. A critter perched on a tree is
	## drawn over it: a perched bird stands at its tree's own depth, so the trees
	## come before the birds.
	scene_renderings : Scene -> List(Rendered)
	scene_renderings = |scene| {
		trucks =
			match scene.truck {
				Ok(truck) => [truck]
				Err(NoTruck) | Err(BehindCamera) => []
			}
		Rendered.depth_sorted_renderings(
			[
				scene.trees,
				scene.birds,
				scene.towers,
				scene.billboards,
				scene.cats,
				trucks,
				scene.rails,
			].join(),
		)
	}

	## The scene's things as shapes, far to near.
	scene_shapes : Scene -> List(Shapes.Shape)
	scene_shapes = |scene|
		Scene.scene_renderings(scene).join_map(|rendering| rendering.picture.to_shapes())

	## Each of `trees` rendered, told how many of the others are nearer, which is
	## all a tree needs of them.
	tree_renderings : List(Pipeline.Sighted(Conifer)), Pixels -> List(Rendered)
	tree_renderings = |trees, cam_focal| {
		forwards = trees.map(|tree| tree.spot.foot().forward())
		trees.map(
			|tree| {
				nearer_count = nearer_tree_count(forwards, tree.spot.foot().forward())
				Pipeline.rendering_of(
					tree,
					{ cam_focal, context: { nearer_tree_count: nearer_count } },
				)
			},
		)
	}
}

## How many of the trees at `forwards` are nearer than `forward`.
nearer_tree_count : List(Distance), Distance -> U16
nearer_tree_count = |forwards, forward| {
	count = forwards.count_if(|other| other < forward)
	count.to_u16_try() ?? crash "Scene.nearer_tree_count: more than 65,535 trees in view"
}

spread_forwards : List(Distance)
spread_forwards = [10.0, 20.0, 30.0, 40.0, 50.0].map(Distance.metres)

expect nearer_tree_count(spread_forwards, Distance.metres(10.0)) == 0
expect nearer_tree_count(spread_forwards, Distance.metres(30.0)) == 2
expect nearer_tree_count(spread_forwards, Distance.metres(50.0)) == 4
expect nearer_tree_count(spread_forwards, Distance.metres(60.0)) == 5
expect nearer_tree_count(spread_forwards, Distance.metres(5.0)) == 0
expect nearer_tree_count([], Distance.metres(10.0)) == 0

tied_forwards : List(Distance)
tied_forwards = List.repeat(Distance.metres(20.0), 4)

expect nearer_tree_count(tied_forwards, Distance.metres(20.0)) == 0
expect nearer_tree_count(tied_forwards, Distance.metres(20.1)) == 4
expect nearer_tree_count(tied_forwards, Distance.metres(19.9)) == 0
