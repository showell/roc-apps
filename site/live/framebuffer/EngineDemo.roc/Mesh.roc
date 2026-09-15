# Mesh -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cordic
import MathLib

Mesh :: [].{
	Vertex : { vp_x : I64, vp_y : I64, vp_z : I64, vn_x : I64, vn_y : I64, vn_z : I64, vu : I64, vv : I64, v_color : I64 }
	MeshPrimitive : [MeshTriangles, MeshLines, MeshPoints]
	Mesh : { mesh_verts : List(Mesh.Vertex), mesh_indices : List(I64), mesh_vert_count : I64, mesh_index_count : I64, mesh_primitive : Mesh.MeshPrimitive }
	MeshBounds : { mb_min_x : I64, mb_min_y : I64, mb_min_z : I64, mb_max_x : I64, mb_max_y : I64, mb_max_z : I64 }

	vertex : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Mesh.Vertex
	vertex = |px, py, pz, nx, ny, nz, u, v, color| { vp_x: px, vp_y: py, vp_z: pz, vn_x: nx, vn_y: ny, vn_z: nz, vu: u, vv: v, v_color: color }

	vertex_pos : I64, I64, I64 -> Mesh.Vertex
	vertex_pos = |x, y, z| { vp_x: x, vp_y: y, vp_z: z, vn_x: 0, vn_y: 0, vn_z: 1000, vu: 0, vv: 0, v_color: 16777215 }

	vertex_pos_normal : I64, I64, I64, I64, I64, I64 -> Mesh.Vertex
	vertex_pos_normal = |px, py, pz, nx, ny, nz| { vp_x: px, vp_y: py, vp_z: pz, vn_x: nx, vn_y: ny, vn_z: nz, vu: 0, vv: 0, v_color: 16777215 }

	vertex_pos_uv : I64, I64, I64, I64, I64 -> Mesh.Vertex
	vertex_pos_uv = |px, py, pz, u, v| { vp_x: px, vp_y: py, vp_z: pz, vn_x: 0, vn_y: 0, vn_z: 1000, vu: u, vv: v, v_color: 16777215 }

	mesh_new : List(Mesh.Vertex), List(I64) -> Mesh.Mesh
	mesh_new = |verts, indices| { mesh_verts: verts, mesh_indices: indices, mesh_vert_count: U64.to_i64_wrap(List.len(verts)), mesh_index_count: U64.to_i64_wrap(List.len(indices)), mesh_primitive: MeshTriangles }

	mesh_empty : Mesh.Mesh
	mesh_empty = { mesh_verts: [], mesh_indices: [], mesh_vert_count: 0, mesh_index_count: 0, mesh_primitive: MeshTriangles }

	mesh_vertex_at : Mesh.Mesh, I64 -> Mesh.Vertex
	mesh_vertex_at = |m, i| (List.get(m.mesh_verts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))

	mesh_index_at : Mesh.Mesh, I64 -> I64
	mesh_index_at = |m, i| (List.get(m.mesh_indices, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))

	mesh_triangle_count : Mesh.Mesh -> I64
	mesh_triangle_count = |m| I64.div_trunc_by(m.mesh_index_count, 3)

	mesh_cube : I64 -> Mesh.Mesh
	mesh_cube = |half| ({
		h = half
		n = (0 - half)
		verts = [vertex(n, n, h, 0, 0, 1000, 0, 0, 16777215), vertex(h, n, h, 0, 0, 1000, 1000, 0, 16777215), vertex(h, h, h, 0, 0, 1000, 1000, 1000, 16777215), vertex(n, h, h, 0, 0, 1000, 0, 1000, 16777215), vertex(h, n, n, 0, 0, (-1000), 0, 0, 16777215), vertex(n, n, n, 0, 0, (-1000), 1000, 0, 16777215), vertex(n, h, n, 0, 0, (-1000), 1000, 1000, 16777215), vertex(h, h, n, 0, 0, (-1000), 0, 1000, 16777215), vertex(n, n, n, (-1000), 0, 0, 0, 0, 16777215), vertex(n, n, h, (-1000), 0, 0, 1000, 0, 16777215), vertex(n, h, h, (-1000), 0, 0, 1000, 1000, 16777215), vertex(n, h, n, (-1000), 0, 0, 0, 1000, 16777215), vertex(h, n, h, 1000, 0, 0, 0, 0, 16777215), vertex(h, n, n, 1000, 0, 0, 1000, 0, 16777215), vertex(h, h, n, 1000, 0, 0, 1000, 1000, 16777215), vertex(h, h, h, 1000, 0, 0, 0, 1000, 16777215), vertex(n, h, h, 0, 1000, 0, 0, 0, 16777215), vertex(h, h, h, 0, 1000, 0, 1000, 0, 16777215), vertex(h, h, n, 0, 1000, 0, 1000, 1000, 16777215), vertex(n, h, n, 0, 1000, 0, 0, 1000, 16777215), vertex(n, n, n, 0, (-1000), 0, 0, 0, 16777215), vertex(h, n, n, 0, (-1000), 0, 1000, 0, 16777215), vertex(h, n, h, 0, (-1000), 0, 1000, 1000, 16777215), vertex(n, n, h, 0, (-1000), 0, 0, 1000, 16777215)]
		indices = [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11, 12, 13, 14, 12, 14, 15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23]
		mesh_new(verts, indices)
	})

	mesh_plane : I64, I64 -> Mesh.Mesh
	mesh_plane = |half_w, half_h| ({
		verts = [vertex((0 - half_w), 0, (0 - half_h), 0, 1000, 0, 0, 0, 16777215), vertex(half_w, 0, (0 - half_h), 0, 1000, 0, 1000, 0, 16777215), vertex(half_w, 0, half_h, 0, 1000, 0, 1000, 1000, 16777215), vertex((0 - half_w), 0, half_h, 0, 1000, 0, 0, 1000, 16777215)]
		indices = [0, 2, 1, 0, 3, 2]
		mesh_new(verts, indices)
	})

	mesh_pyramid : I64, I64 -> Mesh.Mesh
	mesh_pyramid = |half_base, height| ({
		b = half_base
		nb = (0 - half_base)
		verts = [vertex(0, height, 0, 0, 1000, 0, 500, 0, 16777215), vertex(nb, 0, b, 0, 0, 1000, 0, 1000, 16777215), vertex(b, 0, b, 0, 0, 1000, 1000, 1000, 16777215), vertex(b, 0, nb, 0, 0, (-1000), 1000, 1000, 16777215), vertex(nb, 0, nb, 0, 0, (-1000), 0, 1000, 16777215)]
		indices = [0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1, 1, 4, 3, 1, 3, 2]
		mesh_new(verts, indices)
	})

	msg_grid_indices : I64, I64, I64, I64, List(I64) -> List(I64)
	msg_grid_indices = |segs, rings, i, j, acc| (if (i >= rings) { acc } else { (if (j >= segs) { msg_grid_indices(segs, rings, (i + 1), 0, acc) } else { ({
		a = ((i * (segs + 1)) + j)
		b = (a + 1)
		c = ((a + segs) + 1)
		d = (c + 1)
		acc2 = List.append(List.append(List.append(acc, a), b), d)
		acc3 = List.append(List.append(List.append(acc2, a), d), c)
		msg_grid_indices(segs, rings, i, (j + 1), acc3)
	}) }) })

	mesh_sphere : I64, I64, I64 -> Mesh.Mesh
	mesh_sphere = |radius, segs, rings| ({
		verts = msg_sphere_verts(radius, segs, rings, 0, 0, [])
		mesh_new(verts, msg_grid_indices(segs, rings, 0, 0, []))
	})

	msg_sphere_verts : I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_sphere_verts = |radius, segs, rings, i, j, acc| (if (i > rings) { acc } else { (if (j > segs) { msg_sphere_verts(radius, segs, rings, (i + 1), 0, acc) } else { ({
		phi = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_pi * i), rings))
		theta = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_two_pi * j), segs))
		ny = phi.cos_val
		ring_r = phi.sin_val
		nx = I64.div_trunc_by((ring_r * theta.cos_val), 1000)
		nz = I64.div_trunc_by((ring_r * theta.sin_val), 1000)
		vtx = vertex(I64.div_trunc_by((radius * nx), 1000), I64.div_trunc_by((radius * ny), 1000), I64.div_trunc_by((radius * nz), 1000), nx, ny, nz, I64.div_trunc_by((j * 1000), segs), I64.div_trunc_by((i * 1000), rings), 16777215)
		msg_sphere_verts(radius, segs, rings, i, (j + 1), List.append(acc, vtx))
	}) }) })

	mesh_cylinder : I64, I64, I64 -> Mesh.Mesh
	mesh_cylinder = |radius, half_h, segs| ({
		side = msg_cyl_side(radius, half_h, segs, 0, 0, [])
		capped = msg_cyl_caps(radius, half_h, segs, side)
		idx = msg_grid_indices(segs, 1, 0, 0, [])
		top_base = (2 * (segs + 1))
		bot_base = ((top_base + segs) + 2)
		idx2 = msg_fan_indices(top_base, segs, True, 0, idx)
		mesh_new(capped, msg_fan_indices(bot_base, segs, False, 0, idx2))
	})

	msg_cyl_side : I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_cyl_side = |radius, half_h, segs, row, j, acc| (if (row > 1) { acc } else { (if (j > segs) { msg_cyl_side(radius, half_h, segs, (row + 1), 0, acc) } else { ({
		t = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_two_pi * j), segs))
		y = (if (row == 0) { half_h } else { (0 - half_h) })
		vtx = vertex(I64.div_trunc_by((radius * t.cos_val), 1000), y, I64.div_trunc_by((radius * t.sin_val), 1000), t.cos_val, 0, t.sin_val, I64.div_trunc_by((j * 1000), segs), (row * 1000), 16777215)
		msg_cyl_side(radius, half_h, segs, row, (j + 1), List.append(acc, vtx))
	}) }) })

	msg_cyl_caps : I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_cyl_caps = |radius, half_h, segs, acc| ({
		top = msg_cap_ring(radius, half_h, 1000, segs, 0, List.append(acc, vertex(0, half_h, 0, 0, 1000, 0, 500, 500, 16777215)))
		msg_cap_ring(radius, (0 - half_h), (-1000), segs, 0, List.append(top, vertex(0, (0 - half_h), 0, 0, (-1000), 0, 500, 500, 16777215)))
	})

	msg_cap_ring : I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_cap_ring = |radius, y, ny, segs, j, acc| (if (j > segs) { acc } else { ({
		t = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_two_pi * j), segs))
		vtx = vertex(I64.div_trunc_by((radius * t.cos_val), 1000), y, I64.div_trunc_by((radius * t.sin_val), 1000), 0, ny, 0, (500 + I64.div_trunc_by(t.cos_val, 2)), (500 + I64.div_trunc_by(t.sin_val, 2)), 16777215)
		msg_cap_ring(radius, y, ny, segs, (j + 1), List.append(acc, vtx))
	}) })

	msg_fan_indices : I64, I64, Bool, I64, List(I64) -> List(I64)
	msg_fan_indices = |base, segs, flip, j, acc| (if (j >= segs) { acc } else { ({
		r0 = ((base + 1) + j)
		r1 = ((base + 2) + j)
		acc2 = (if flip { List.append(List.append(List.append(acc, base), r1), r0) } else { List.append(List.append(List.append(acc, base), r0), r1) })
		msg_fan_indices(base, segs, flip, (j + 1), acc2)
	}) })

	mesh_cone : I64, I64, I64 -> Mesh.Mesh
	mesh_cone = |radius, height, segs| ({
		slant = MathLib.math_isqrt(((height * height) + (radius * radius)))
		rim = msg_cone_rim(radius, height, slant, segs, 0, [])
		apexed = msg_cone_apexes(radius, height, slant, segs, 0, rim)
		based = msg_cap_ring(radius, 0, (-1000), segs, 0, List.append(apexed, vertex(0, 0, 0, 0, (-1000), 0, 500, 500, 16777215)))
		side_idx = msg_cone_side_indices(segs, 0, [])
		mesh_new(based, msg_fan_indices(((2 * segs) + 1), segs, False, 0, side_idx))
	})

	msg_cone_rim : I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_cone_rim = |radius, height, slant, segs, j, acc| (if (j > segs) { acc } else { ({
		t = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_two_pi * j), segs))
		nx = I64.div_trunc_by((height * t.cos_val), slant)
		nz = I64.div_trunc_by((height * t.sin_val), slant)
		ny = I64.div_trunc_by((radius * 1000), slant)
		vtx = vertex(I64.div_trunc_by((radius * t.cos_val), 1000), 0, I64.div_trunc_by((radius * t.sin_val), 1000), nx, ny, nz, I64.div_trunc_by((j * 1000), segs), 1000, 16777215)
		msg_cone_rim(radius, height, slant, segs, (j + 1), List.append(acc, vtx))
	}) })

	msg_cone_apexes : I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_cone_apexes = |radius, height, slant, segs, j, acc| (if (j >= segs) { acc } else { ({
		t = Cordic.cordic_sincos((I64.div_trunc_by((Cordic.cordic_two_pi * j), segs) + I64.div_trunc_by(Cordic.cordic_pi, segs)))
		nx = I64.div_trunc_by((height * t.cos_val), slant)
		nz = I64.div_trunc_by((height * t.sin_val), slant)
		ny = I64.div_trunc_by((radius * 1000), slant)
		vtx = vertex(0, height, 0, nx, ny, nz, (I64.div_trunc_by((j * 1000), segs) + I64.div_trunc_by(500, segs)), 0, 16777215)
		msg_cone_apexes(radius, height, slant, segs, (j + 1), List.append(acc, vtx))
	}) })

	msg_cone_side_indices : I64, I64, List(I64) -> List(I64)
	msg_cone_side_indices = |segs, j, acc| (if (j >= segs) { acc } else { ({
		acc2 = List.append(List.append(List.append(acc, j), (j + 1)), ((segs + 1) + j))
		msg_cone_side_indices(segs, (j + 1), acc2)
	}) })

	mesh_torus : I64, I64, I64, I64 -> Mesh.Mesh
	mesh_torus = |major, minor, segs_u, segs_v| ({
		verts = msg_torus_verts(major, minor, segs_u, segs_v, 0, 0, [])
		mesh_new(verts, msg_grid_indices(segs_u, segs_v, 0, 0, []))
	})

	msg_torus_verts : I64, I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	msg_torus_verts = |major, minor, segs_u, segs_v, i, j, acc| (if (i > segs_v) { acc } else { (if (j > segs_u) { msg_torus_verts(major, minor, segs_u, segs_v, (i + 1), 0, acc) } else { ({
		ph = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_two_pi * i), segs_v))
		th = Cordic.cordic_sincos(I64.div_trunc_by((Cordic.cordic_two_pi * j), segs_u))
		ring = (major + I64.div_trunc_by((minor * ph.cos_val), 1000))
		nx = I64.div_trunc_by((ph.cos_val * th.cos_val), 1000)
		nz = I64.div_trunc_by((ph.cos_val * th.sin_val), 1000)
		vtx = vertex(I64.div_trunc_by((ring * th.cos_val), 1000), I64.div_trunc_by((minor * ph.sin_val), 1000), I64.div_trunc_by((ring * th.sin_val), 1000), nx, ph.sin_val, nz, I64.div_trunc_by((j * 1000), segs_u), I64.div_trunc_by((i * 1000), segs_v), 16777215)
		msg_torus_verts(major, minor, segs_u, segs_v, i, (j + 1), List.append(acc, vtx))
	}) }) })

	mesh_bounds : Mesh.Mesh -> Mesh.MeshBounds
	mesh_bounds = |m| (if (m.mesh_vert_count == 0) { { mb_min_x: 0, mb_min_y: 0, mb_min_z: 0, mb_max_x: 0, mb_max_y: 0, mb_max_z: 0 } } else { ({
		v0 = mesh_vertex_at(m, 0)
		mesh_bounds_loop(m, 1, m.mesh_vert_count, { mb_min_x: v0.vp_x, mb_min_y: v0.vp_y, mb_min_z: v0.vp_z, mb_max_x: v0.vp_x, mb_max_y: v0.vp_y, mb_max_z: v0.vp_z })
	}) })

	mesh_bounds_loop : Mesh.Mesh, I64, I64, Mesh.MeshBounds -> Mesh.MeshBounds
	mesh_bounds_loop = |m, i, n, b| (if (i >= n) { b } else { ({
		v = mesh_vertex_at(m, i)
		b2 = { mb_min_x: mesh_min(b.mb_min_x, v.vp_x), mb_min_y: mesh_min(b.mb_min_y, v.vp_y), mb_min_z: mesh_min(b.mb_min_z, v.vp_z), mb_max_x: mesh_max(b.mb_max_x, v.vp_x), mb_max_y: mesh_max(b.mb_max_y, v.vp_y), mb_max_z: mesh_max(b.mb_max_z, v.vp_z) }
		mesh_bounds_loop(m, (i + 1), n, b2)
	}) })

	mesh_min : I64, I64 -> I64
	mesh_min = |a, b| (if (a < b) { a } else { b })

	mesh_max : I64, I64 -> I64
	mesh_max = |a, b| (if (a > b) { a } else { b })

	mesh_from_heightmap : List(I64), I64, I64, I64 -> Mesh.Mesh
	mesh_from_heightmap = |cells, grid_size, spacing, height_scale| ({
		verts = mfh_build_verts(cells, grid_size, spacing, height_scale, 0, 0, [])
		indices = mfh_build_indices(grid_size, 0, 0, [])
		mesh_new(verts, indices)
	})

	mfh_build_verts : List(I64), I64, I64, I64, I64, I64, List(Mesh.Vertex) -> List(Mesh.Vertex)
	mfh_build_verts = |cells, size, spacing, h_scale, x, z, acc| (if (z >= size) { acc } else { (if (x >= size) { mfh_build_verts(cells, size, spacing, h_scale, 0, (z + 1), acc) } else { ({
		height = ((List.get(cells, I64.to_u64_wrap(((z * size) + x))) ?? crash("list-at out of range")) * h_scale)
		px = ((x * spacing) - I64.div_trunc_by((size * spacing), 2))
		pz = ((z * spacing) - I64.div_trunc_by((size * spacing), 2))
		u = I64.div_trunc_by((x * 1000), (size - 1))
		v = I64.div_trunc_by((z * 1000), (size - 1))
		ny = 1000
		vert = vertex(px, height, pz, 0, ny, 0, u, v, 9139029)
		mfh_build_verts(cells, size, spacing, h_scale, (x + 1), z, List.append(acc, vert))
	}) }) })

	mfh_build_indices : I64, I64, I64, List(I64) -> List(I64)
	mfh_build_indices = |size, x, z, acc| (if (z >= (size - 1)) { acc } else { (if (x >= (size - 1)) { mfh_build_indices(size, 0, (z + 1), acc) } else { ({
		tl = ((z * size) + x)
		tr = (tl + 1)
		bl = (tl + size)
		br = (bl + 1)
		acc2 = List.append(List.append(List.append(acc, tl), bl), tr)
		acc3 = List.append(List.append(List.append(acc2, tr), bl), br)
		mfh_build_indices(size, (x + 1), z, acc3)
	}) }) })

	format_mesh : Mesh.Mesh -> Str
	format_mesh = |m| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("Mesh(", I64.to_str(m.mesh_vert_count)), "v, "), I64.to_str(m.mesh_index_count)), "i, "), I64.to_str(mesh_triangle_count(m))), "t)")

	format_vertex : Mesh.Vertex -> Str
	format_vertex = |v| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("(", I64.to_str(v.vp_x)), ","), I64.to_str(v.vp_y)), ","), I64.to_str(v.vp_z)), ")")

	format_bounds : Mesh.MeshBounds -> Str
	format_bounds = |b| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("[", I64.to_str(b.mb_min_x)), ".."), I64.to_str(b.mb_max_x)), ", "), I64.to_str(b.mb_min_y)), ".."), I64.to_str(b.mb_max_y)), ", "), I64.to_str(b.mb_min_z)), ".."), I64.to_str(b.mb_max_z)), "]")

	eq_MeshPrimitive : Mesh.MeshPrimitive, Mesh.MeshPrimitive -> Bool
	eq_MeshPrimitive = |ex, ey| (match ex {
		MeshTriangles => (match ey {
			MeshTriangles => True
			_ => False
		})
		MeshLines => (match ey {
			MeshLines => True
			_ => False
		})
		MeshPoints => (match ey {
			MeshPoints => True
			_ => False
		})
	})
}
