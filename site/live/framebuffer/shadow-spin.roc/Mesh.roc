# Mesh -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Mesh :: [].{
	Vertex := { vp_x : I64, vp_y : I64, vp_z : I64, vn_x : I64, vn_y : I64, vn_z : I64, vu : I64, vv : I64, v_color : I64 }.{
		is_eq : Mesh.Vertex, Mesh.Vertex -> Bool
		is_eq = |a, b| eq_Vertex(a, b)
	}
	MeshPrimitive : [MeshTriangles, MeshLines, MeshPoints]
	Mesh := { mesh_verts : List(Mesh.Vertex), mesh_indices : List(I64), mesh_vert_count : I64, mesh_index_count : I64, mesh_primitive : Mesh.MeshPrimitive }.{
		is_eq : Mesh.Mesh, Mesh.Mesh -> Bool
		is_eq = |a, b| eq_Mesh(a, b)
	}
	MeshBounds := { mb_min_x : I64, mb_min_y : I64, mb_min_z : I64, mb_max_x : I64, mb_max_y : I64, mb_max_z : I64 }.{
		is_eq : Mesh.MeshBounds, Mesh.MeshBounds -> Bool
		is_eq = |a, b| eq_MeshBounds(a, b)
	}

	vertex : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Mesh.Vertex
	vertex = |px, py, pz, nx, ny, nz, u, v, color| Mesh.Vertex.{ vp_x: px, vp_y: py, vp_z: pz, vn_x: nx, vn_y: ny, vn_z: nz, vu: u, vv: v, v_color: color }

	mesh_new : List(Mesh.Vertex), List(I64) -> Mesh.Mesh
	mesh_new = |verts, indices| Mesh.Mesh.{ mesh_verts: verts, mesh_indices: indices, mesh_vert_count: U64.to_i64_wrap(List.len(verts)), mesh_index_count: U64.to_i64_wrap(List.len(indices)), mesh_primitive: MeshTriangles }

	mesh_vertex_at : Mesh.Mesh, I64 -> Mesh.Vertex
	mesh_vertex_at = |m, i| (List.get(m.mesh_verts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))

	mesh_index_at : Mesh.Mesh, I64 -> I64
	mesh_index_at = |m, i| (List.get(m.mesh_indices, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))

	mesh_cube : I64 -> Mesh.Mesh
	mesh_cube = |half| ({
		h : I64
		h = half
		n : I64
		n = (0 - half)
		verts = [vertex(n, n, h, 0, 0, 1000, 0, 0, 16777215), vertex(h, n, h, 0, 0, 1000, 1000, 0, 16777215), vertex(h, h, h, 0, 0, 1000, 1000, 1000, 16777215), vertex(n, h, h, 0, 0, 1000, 0, 1000, 16777215), vertex(h, n, n, 0, 0, (-1000), 0, 0, 16777215), vertex(n, n, n, 0, 0, (-1000), 1000, 0, 16777215), vertex(n, h, n, 0, 0, (-1000), 1000, 1000, 16777215), vertex(h, h, n, 0, 0, (-1000), 0, 1000, 16777215), vertex(n, n, n, (-1000), 0, 0, 0, 0, 16777215), vertex(n, n, h, (-1000), 0, 0, 1000, 0, 16777215), vertex(n, h, h, (-1000), 0, 0, 1000, 1000, 16777215), vertex(n, h, n, (-1000), 0, 0, 0, 1000, 16777215), vertex(h, n, h, 1000, 0, 0, 0, 0, 16777215), vertex(h, n, n, 1000, 0, 0, 1000, 0, 16777215), vertex(h, h, n, 1000, 0, 0, 1000, 1000, 16777215), vertex(h, h, h, 1000, 0, 0, 0, 1000, 16777215), vertex(n, h, h, 0, 1000, 0, 0, 0, 16777215), vertex(h, h, h, 0, 1000, 0, 1000, 0, 16777215), vertex(h, h, n, 0, 1000, 0, 1000, 1000, 16777215), vertex(n, h, n, 0, 1000, 0, 0, 1000, 16777215), vertex(n, n, n, 0, (-1000), 0, 0, 0, 16777215), vertex(h, n, n, 0, (-1000), 0, 1000, 0, 16777215), vertex(h, n, h, 0, (-1000), 0, 1000, 1000, 16777215), vertex(n, n, h, 0, (-1000), 0, 0, 1000, 16777215)]
		indices : List(I64)
		indices = [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11, 12, 13, 14, 12, 14, 15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23]
		mesh_new(verts, indices)
	})

	mesh_plane : I64, I64 -> Mesh.Mesh
	mesh_plane = |half_w, half_h| ({
		verts = [vertex((0 - half_w), 0, (0 - half_h), 0, 1000, 0, 0, 0, 16777215), vertex(half_w, 0, (0 - half_h), 0, 1000, 0, 1000, 0, 16777215), vertex(half_w, 0, half_h, 0, 1000, 0, 1000, 1000, 16777215), vertex((0 - half_w), 0, half_h, 0, 1000, 0, 0, 1000, 16777215)]
		indices : List(I64)
		indices = [0, 2, 1, 0, 3, 2]
		mesh_new(verts, indices)
	})

	mesh_bounds : Mesh.Mesh -> Mesh.MeshBounds
	mesh_bounds = |m| (if (m.mesh_vert_count == 0) { Mesh.MeshBounds.{ mb_min_x: 0, mb_min_y: 0, mb_min_z: 0, mb_max_x: 0, mb_max_y: 0, mb_max_z: 0 } } else { ({
		v0 = mesh_vertex_at(m, 0)
		mesh_bounds_loop(m, 1, m.mesh_vert_count, Mesh.MeshBounds.{ mb_min_x: v0.vp_x, mb_min_y: v0.vp_y, mb_min_z: v0.vp_z, mb_max_x: v0.vp_x, mb_max_y: v0.vp_y, mb_max_z: v0.vp_z })
	}) })

	mesh_bounds_loop : Mesh.Mesh, I64, I64, Mesh.MeshBounds -> Mesh.MeshBounds
	mesh_bounds_loop = |m, i, n, b| (if (i >= n) { b } else { ({
		v = mesh_vertex_at(m, i)
		b2 = Mesh.MeshBounds.{ mb_min_x: mesh_min(b.mb_min_x, v.vp_x), mb_min_y: mesh_min(b.mb_min_y, v.vp_y), mb_min_z: mesh_min(b.mb_min_z, v.vp_z), mb_max_x: mesh_max(b.mb_max_x, v.vp_x), mb_max_y: mesh_max(b.mb_max_y, v.vp_y), mb_max_z: mesh_max(b.mb_max_z, v.vp_z) }
		mesh_bounds_loop(m, (i + 1), n, b2)
	}) })

	mesh_min : I64, I64 -> I64
	mesh_min = |a, b| (if (a < b) { a } else { b })

	mesh_max : I64, I64 -> I64
	mesh_max = |a, b| (if (a > b) { a } else { b })

	eq_Vertex : Mesh.Vertex, Mesh.Vertex -> Bool
	eq_Vertex = |ex, ey| (((((((((ex.vp_x == ey.vp_x) and (ex.vp_y == ey.vp_y)) and (ex.vp_z == ey.vp_z)) and (ex.vn_x == ey.vn_x)) and (ex.vn_y == ey.vn_y)) and (ex.vn_z == ey.vn_z)) and (ex.vu == ey.vu)) and (ex.vv == ey.vv)) and (ex.v_color == ey.v_color))

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

	eq_Mesh : Mesh.Mesh, Mesh.Mesh -> Bool
	eq_Mesh = |ex, ey| (((((ex.mesh_verts == ey.mesh_verts) and (ex.mesh_indices == ey.mesh_indices)) and (ex.mesh_vert_count == ey.mesh_vert_count)) and (ex.mesh_index_count == ey.mesh_index_count)) and eq_MeshPrimitive(ex.mesh_primitive, ey.mesh_primitive))

	eq_MeshBounds : Mesh.MeshBounds, Mesh.MeshBounds -> Bool
	eq_MeshBounds = |ex, ey| ((((((ex.mb_min_x == ey.mb_min_x) and (ex.mb_min_y == ey.mb_min_y)) and (ex.mb_min_z == ey.mb_min_z)) and (ex.mb_max_x == ey.mb_max_x)) and (ex.mb_max_y == ey.mb_max_y)) and (ex.mb_max_z == ey.mb_max_z))
}
