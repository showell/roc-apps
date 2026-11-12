## Scene gathers what one frame shows beside the road: the trees, towers,
## billboards, cats, guard rails, the truck and the birds in view, each found by
## its own sighting and rendered as soon as it is found. Past the sighting
## nothing asks what kind a thing is, so each field holds only renderings. A
## scene is worked out each frame from the ride's instant and the route.
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
import Sky
import TowerSighting
import TreeSighting
import Truck
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
	## clock. The truck's lights are worked out from the clock and the truck's
	## pace, and in play `FrameView.ride_facts` is the one builder of these
	## facts, so the headlights always agree with `clock`.
	RideFacts : {
		encounter_stage : Animation.Stage,
		truck : { route_position : Distance, truck : Truck },
		clock : Clock,
	}

	## Everything `camera` sees of `road`, each thing rendered as it is sighted.
	scene_in_view : RoadAhead.RoadView,
	{
		camera : Pipeline.SightingCamera,
		facts : Scene.RideFacts,
	} -> Scene
	scene_in_view = |road, { camera, facts }| {
		lens_and_light = {
			focal_length: camera.focal_length,
			darkness: Sky.darkness_at(facts.clock),
		}
		vantage = camera.vantage
		encounter = { camera, encounter_stage: facts.encounter_stage }
		birds_seen = EncounterSighting.birds_in_view(road, encounter)
		cats_seen = EncounterSighting.cats_in_view(road, encounter)
		trees_seen = TreeSighting.trees_in_view(road, camera)
		trucks =
			match TruckSighting.truck_in_view(road, { vantage, truck: facts.truck }) {
				Ok(truck) => [Pipeline.rendering_of(truck, lens_and_light)]
				Err(OutOfSight) => []
			}
		{
			trees: trees_seen.map(|tree| Pipeline.rendering_of(tree, lens_and_light)),
			birds: birds_seen.map(|bird| Pipeline.rendering_of(bird, lens_and_light)),
			towers: TowerSighting.towers_in_view(road, { vantage, clock: facts.clock }).map(
				|tower| Pipeline.rendering_of(tower, lens_and_light),
			),
			billboards: BillboardSighting.billboards_in_view(road, camera).map(
				|billboard| Pipeline.rendering_of(billboard, lens_and_light),
			),
			cats: cats_seen.map(|cat| Pipeline.rendering_of(cat, lens_and_light)),
			trucks,
			rails: RailSighting.rail_quads_in_view(road, vantage).keep_oks(
				|quad| GuardRail.quad_rendering(quad, lens_and_light),
			),
		}
	}

	## The scene's things as shapes, far to near: a list for each thing.
	scene_shape_lists : Scene -> List(List(Shapes.Shape))
	scene_shape_lists = |scene|
		Scene.scene_renderings(scene).map(|rendering| rendering.sprite().to_shapes())

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
