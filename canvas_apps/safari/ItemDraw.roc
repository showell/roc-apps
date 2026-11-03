# ItemDraw -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Billboards
import CatDraw
import CatPlan
import Critter
import DepthSort
import Frame
import Geom
import GuardRail
import Lens
import Mountains
import Paint
import Render
import SceneLimits
import Tower
import TowerPlan
import Tree
import TreePlan
import TruckDraw
import TruckPlan
import RocBird
import World

ItemDraw :: [].{

	closer_count : List(TreePlan.TreeItem), F64, I64 -> I64
	closer_count = |ts, f, i| (
		if (i >= ts.len().to_i64_wrap()) {
			0
		} else {
			(
				if ((List.get(ts, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).fwd < f) {
					(1 + closer_count(ts, f, (i + 1)))
				} else {
					closer_count(ts, f, (i + 1))
				}
			)
		}
	)

	crown_shade_of : F64 -> F64
	crown_shade_of = |fwd| (
		{
			raw = (1.0 - (fwd / SceneLimits.crown_shade_dist))
			(
				if (raw < 0.0) {
					0.0
				} else {
					(
						if (raw > 1.0) {
							1.0
						} else {
							raw
						}
					)
				}
			)
		}
	)

	draw_one_tree : List(TreePlan.TreeItem), I64, F64 -> List(Paint.DrawCmd)
	draw_one_tree = |ts, i, cf| (
		{
			t = (List.get(ts, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))
			Tree.tree_draw(t.right, t.fwd, t.height, t.color, cf, Lens.camera_w, (closer_count(ts, t.fwd, 0) < 4), (t.fwd < SceneLimits.detail_dist), crown_shade_of(t.fwd))
		}
	)

	## Where a mast's four footprint corners stand in the rider's view.
	tower_footprint : List(World.Segment), List(I64), Frame.Pose, TowerPlan.TowerItem -> Tower.Footprint
	tower_footprint = |w, ch, pose, tw| {
		corner_point = |corner| {
			on_map = Tower.base_corner_ax(corner, tw.a0, tw.x0, tw.yaw)
			Frame.map_pt(w, ch, pose, tw.map, on_map.a, on_map.x)
		}
		{
			back_left: corner_point(BackLeft),
			back_right: corner_point(BackRight),
			front_right: corner_point(FrontRight),
			front_left: corner_point(FrontLeft),
		}
	}

	draw_one_tower : List(World.Segment), List(I64), Frame.Pose, TowerPlan.TowerItem, F64, F64 -> List(Paint.DrawCmd)
	draw_one_tower = |w, ch, pose, tw, cf, step|
		Tower.draw({
			footprint: tower_footprint(w, ch, pose, tw),
			center: Frame.map_pt(w, ch, pose, tw.map, tw.a0, tw.x0),
			cam_focal: cf,
			view_w: Lens.camera_w,
			beacon_phase: (step + tw.off),
		})

	draw_one_critter : Billboards.Billboard, F64 -> List(Paint.DrawCmd)
	draw_one_critter = |b, cf| Critter.critter_draw(b.right, b.fwd, b.height, b.cp, b.face_right, cf, Lens.camera_w)

	draw_one_cat : CatPlan.CatItem, F64 -> List(Paint.DrawCmd)
	draw_one_cat = |k, cf| CatDraw.cat_draw(k.right, k.fwd, k.height, k.pose_idx, k.lift, cf, Lens.camera_w)

	draw_one_truck : List(World.Segment), List(I64), Frame.Pose, TruckPlan.TruckAt, Bool, F64, F64 -> List(Paint.DrawCmd)
	draw_one_truck = |w, ch, pose, tk, braking, cf, step|
		TruckDraw.draw({
			road: { world: w, chain: ch, pose, segment: tk.d },
			center: {
				along: tk.along,
				across: ((List.get(w, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(tk.d)) ?? crash ("list-at out of range")))) ?? crash ("list-at out of range")).width / 2.0),
			},
			lights: {
				headlights: if Mountains.sun_behind_mountains(step) On else Off,
				brake_lights: if braking On else Off,
			},
			cam_focal: cf,
			view_w: Lens.camera_w,
		})

	draw_item : List(World.Segment), List(I64), Frame.Pose, Render.Collected, DepthSort.DepthKey, Bool, F64, F64 -> List(Paint.DrawCmd)
	draw_item = |w, ch, pose, c, it, braking, cf, step| (match it.kind {
		KTree => draw_one_tree(c.trees, it.i, cf)
		KTower => draw_one_tower(w, ch, pose, (List.get(c.towers, I64.to_u64_wrap(it.i)) ?? crash ("list-at out of range")), cf, step)
		KRail => GuardRail.rail_draw_poly((List.get(c.rails, I64.to_u64_wrap(it.i)) ?? crash ("list-at out of range")), cf, Lens.camera_w)
		KCow => draw_one_critter((List.get(c.cows, I64.to_u64_wrap(it.i)) ?? crash ("list-at out of range")), cf)
		KCat => draw_one_cat((List.get(c.cats, I64.to_u64_wrap(it.i)) ?? crash ("list-at out of range")), cf)
		KTruck => draw_one_truck(w, ch, pose, c.truck, braking, cf, step)
		KBird => RocBird.draw_one((List.get(c.birds, I64.to_u64_wrap(it.i)) ?? crash ("bird out of range")), cf, Lens.camera_w)
	})

	# draw_order builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	draw_order : List(World.Segment), List(I64), Frame.Pose, Render.Collected, Bool, F64, F64, I64 -> List(Paint.DrawCmd)
	draw_order = |w, ch, pose, c, braking, cf, step, i| draw_order_onto(w, ch, pose, c, braking, cf, step, i, [])

	draw_order_onto : List(World.Segment), List(I64), Frame.Pose, Render.Collected, Bool, F64, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	draw_order_onto = |w, ch, pose, c, braking, cf, step, i, acc| (
		if (i >= c.order.len().to_i64_wrap()) {
			acc
		} else {
			draw_order_onto(w, ch, pose, c, braking, cf, step, (i + 1), List.concat(acc, draw_item(w, ch, pose, c, (List.get(c.order, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")), braking, cf, step)))
		}
	)
}
