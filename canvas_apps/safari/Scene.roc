## Scene gathers what one frame shows beside the road: the trees, towers,
## billboards, cats, guard rails, the truck and the birds in view, each found by
## its own sighting and rendered as soon as it is found. Past the sighting
## nothing asks what kind a thing is, so each field holds only renderings.
import Animation
import Clock
import Distance
import EncounterSighting
import BillboardSighting
import RoadAhead
import GuardRail
import Pipeline
import RailSighting
import Rendered
import TowerSighting
import TreeSighting
import LitTruck
import TruckSighting
import lib.Shapes

## The things in view, rendered, one field for each sighting that found them.
## It is nominal, not opaque: other modules read its fields, and the frame
## widget builds a scene of some of them to draw a few layers alone.
Scene := {
	trees : List(Rendered),
	birds : List(Rendered),
	towers : List(Rendered),
	billboards : List(Rendered),
	cats : List(Rendered),
	trucks : List(Rendered),
	rails : List(Rendered),
}.{

	## What the sightings read beyond the road: where the encounter on the
	## rider's segment has got to, where the truck is and how it looks, and the
	## clock.
	RideFacts : {
		encounter_stage : Animation.Stage,
		truck : { route_position : Distance, lit_truck : LitTruck },
		clock : Clock,
	}

	## Everything `camera` sees of `road`, each thing rendered as it is sighted.
	scene_in_view : RoadAhead.RoadView,
	{
		camera : Pipeline.SightingCamera,
		facts : Scene.RideFacts,
	} -> Scene
	scene_in_view = |road, { camera, facts }| {
		focal_length = camera.focal_length
		on_road = { road, vantage: camera.vantage }
		encounter = { camera, encounter_stage: facts.encounter_stage }
		birds_seen = EncounterSighting.birds_in_view(road, encounter)
		cats_seen = EncounterSighting.cats_in_view(road, encounter)
		trees_seen = TreeSighting.trees_in_view(road, camera)
		trucks =
			match TruckSighting.truck_in_view(road, { camera, truck: facts.truck }) {
				Ok(truck) => [Pipeline.rendering_of(truck, { focal_length, context: on_road })]
				Err(NoTruck) | Err(BehindCamera) => []
			}
		{
			trees: TreeSighting.tree_renderings(trees_seen, focal_length),
			birds: birds_seen.map(
				|bird| Pipeline.rendering_of(bird, { focal_length, context: {} }),
			),
			towers: TowerSighting.towers_in_view(road, { camera, clock: facts.clock }).map(
				|tower| Pipeline.rendering_of(tower, { focal_length, context: on_road }),
			),
			billboards: BillboardSighting.billboards_in_view(road, camera).map(
				|billboard| Pipeline.rendering_of(billboard, { focal_length, context: {} }),
			),
			cats: cats_seen.map(|cat| Pipeline.rendering_of(cat, { focal_length, context: {} })),
			trucks,
			rails: RailSighting.rail_quads_in_view(road, camera).keep_oks(
				|quad| GuardRail.quad_rendering(quad, focal_length),
			),
		}
	}

	## The scene's things as shapes, far to near: a list for each thing.
	scene_shape_lists : Scene -> List(List(Shapes.Shape))
	scene_shape_lists = |scene|
		Scene.scene_renderings(scene).map(|rendering| rendering.picture().to_shapes())

	## The scene's renderings far to near. The order of the fields they come
	## from breaks ties, so the trees go before the birds: a perched bird stands
	## at its tree's own depth and is drawn over it. It is public for
	## FramePartsBench, which times the sort alone.
	scene_renderings : Scene -> List(Rendered)
	scene_renderings = |scene|
		Rendered.depth_sorted_renderings(
			[
				scene.trees,
				scene.birds,
				scene.towers,
				scene.billboards,
				scene.cats,
				scene.trucks,
				scene.rails,
			].join(),
		)
}
