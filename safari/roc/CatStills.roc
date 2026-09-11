# CatStills -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CatStillsData
import Stills

CatStills :: [].{

	# baked: pose_rest_polys : List(Stills.StillPoly) -- CatStills 5566 literals
	pose_rest_polys : List(Stills.StillPoly)
	pose_rest_polys = CatStillsData.pose_rest_polys

	# baked: pose_stride_polys : List(Stills.StillPoly) -- CatStills 5427 literals
	pose_stride_polys : List(Stills.StillPoly)
	pose_stride_polys = CatStillsData.pose_stride_polys

	# baked: pose_frozen_polys : List(Stills.StillPoly) -- CatStills 5695 literals
	pose_frozen_polys : List(Stills.StillPoly)
	pose_frozen_polys = CatStillsData.pose_frozen_polys

	# baked: pose_coil_polys : List(Stills.StillPoly) -- CatStills 4026 literals
	pose_coil_polys : List(Stills.StillPoly)
	pose_coil_polys = CatStillsData.pose_coil_polys

	# baked: pose_flight_polys : List(Stills.StillPoly) -- CatStills 4315 literals
	pose_flight_polys : List(Stills.StillPoly)
	pose_flight_polys = CatStillsData.pose_flight_polys

	# baked: pose_land_polys : List(Stills.StillPoly) -- CatStills 4463 literals
	pose_land_polys : List(Stills.StillPoly)
	pose_land_polys = CatStillsData.pose_land_polys

	# baked: pose_collapse_polys : List(Stills.StillPoly) -- CatStills 4415 literals
	pose_collapse_polys : List(Stills.StillPoly)
	pose_collapse_polys = CatStillsData.pose_collapse_polys

	cat_polys_for : I64 -> List(Stills.StillPoly)
	cat_polys_for = |i| (if (i == 0) { pose_rest_polys } else { (if (i == 1) { pose_stride_polys } else { (if (i == 2) { pose_frozen_polys } else { (if (i == 3) { pose_coil_polys } else { (if (i == 4) { pose_flight_polys } else { (if (i == 5) { pose_land_polys } else { (if (i == 6) { pose_collapse_polys } else { [] }) }) }) }) }) }) })
}
