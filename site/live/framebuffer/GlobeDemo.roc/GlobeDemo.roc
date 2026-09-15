app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GlobeDemo -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Machine
import MathLib
import Matrix4
import Mesh
import Quaternion
import Scene3D
import TerrainGen

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
IcoTri : { t_ax : I64, t_ay : I64, t_az : I64, t_bx : I64, t_by : I64, t_bz : I64, t_cx : I64, t_cy : I64, t_cz : I64 }
IcoPair : { ip_verts : List(Mesh.Vertex), ip_indices : List(I64) }
GProj : { gp_sx : I64, gp_sy : I64, gp_depth : I64 }

gpu_cmd : I64
gpu_cmd = 3187671040

sw : I64
sw = 640

sh : I64
sh = 480

kb_addr : I64
kb_addr = 28680

mouse_addr : I64
mouse_addr = 28684

earth_r : I64
earth_r = 3000

ico_subdivisions : I64
ico_subdivisions = 3

globe_main! : Machine.Machine, I64 => (Machine.Machine, Str)
globe_main! = |machine, cmd| ({
	(machine1, loaded) = TerrainGen.tg_load_earth_image!(machine)
	(machine2, _tex) = globe_ensure_tex!(machine1, loaded)
	({
		sphere = globe_icosphere(ico_subdivisions, earth_r)
		globe_loop!(machine2, cmd, sphere, 0, 200, 9000, 0)
	})
})

globe_ensure_tex! : Machine.Machine, I64 => (Machine.Machine, I64)
globe_ensure_tex! = |machine, loaded| (if (loaded == 0) { TerrainGen.tg_generate!(machine, PkEarth, 42) } else { (machine, 1) })

globe_icosphere : I64, I64 -> Mesh.Mesh
globe_icosphere = |subdivisions, radius| ({
	base = ico_base_tris(radius)
	subdivided = ico_subdivide_n(base, subdivisions, radius)
	ico_to_mesh(subdivided, radius)
})

ico_subdivide_n : List(IcoTri), I64, I64 -> List(IcoTri)
ico_subdivide_n = |tris, n, radius| (if (n <= 0) { tris } else { ico_subdivide_n(ico_subdivide_all(tris, radius, []), (n - 1), radius) })

ico_subdivide_all : List(IcoTri), I64, List(IcoTri) -> List(IcoTri)
ico_subdivide_all = |tris, radius, acc| ico_subdivide_idx(tris, radius, acc, 0, U64.to_i64_wrap(List.len(tris)))

ico_subdivide_idx : List(IcoTri), I64, List(IcoTri), I64, I64 -> List(IcoTri)
ico_subdivide_idx = |tris, radius, acc, i, n| (if (i >= n) { acc } else { ({
	tri = (List.get(tris, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	sub = ico_subdivide_tri(tri, radius)
	ico_subdivide_idx(tris, radius, List.append(List.append(List.append(List.append(acc, (List.get(sub, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), (List.get(sub, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))), (List.get(sub, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))), (List.get(sub, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))), (i + 1), n)
}) })

ico_subdivide_tri : IcoTri, I64 -> List(IcoTri)
ico_subdivide_tri = |tri, r| ({
	mab = ico_midpoint(tri.t_ax, tri.t_ay, tri.t_az, tri.t_bx, tri.t_by, tri.t_bz, r)
	mbc = ico_midpoint(tri.t_bx, tri.t_by, tri.t_bz, tri.t_cx, tri.t_cy, tri.t_cz, r)
	mca = ico_midpoint(tri.t_cx, tri.t_cy, tri.t_cz, tri.t_ax, tri.t_ay, tri.t_az, r)
	mab_x = (List.get(mab, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	mab_y = (List.get(mab, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
	mab_z = (List.get(mab, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))
	mbc_x = (List.get(mbc, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	mbc_y = (List.get(mbc, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
	mbc_z = (List.get(mbc, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))
	mca_x = (List.get(mca, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	mca_y = (List.get(mca, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
	mca_z = (List.get(mca, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))
	[{ t_ax: tri.t_ax, t_ay: tri.t_ay, t_az: tri.t_az, t_bx: mab_x, t_by: mab_y, t_bz: mab_z, t_cx: mca_x, t_cy: mca_y, t_cz: mca_z }, { t_ax: mab_x, t_ay: mab_y, t_az: mab_z, t_bx: tri.t_bx, t_by: tri.t_by, t_bz: tri.t_bz, t_cx: mbc_x, t_cy: mbc_y, t_cz: mbc_z }, { t_ax: mca_x, t_ay: mca_y, t_az: mca_z, t_bx: mbc_x, t_by: mbc_y, t_bz: mbc_z, t_cx: tri.t_cx, t_cy: tri.t_cy, t_cz: tri.t_cz }, { t_ax: mab_x, t_ay: mab_y, t_az: mab_z, t_bx: mbc_x, t_by: mbc_y, t_bz: mbc_z, t_cx: mca_x, t_cy: mca_y, t_cz: mca_z }]
})

ico_midpoint : I64, I64, I64, I64, I64, I64, I64 -> List(I64)
ico_midpoint = |ax, ay, az, bx, by, bz, r| ({
	mx = I64.div_trunc_by((ax + bx), 2)
	my = I64.div_trunc_by((ay + by), 2)
	mz = I64.div_trunc_by((az + bz), 2)
	len = MathLib.math_isqrt((((mx * mx) + (my * my)) + (mz * mz)))
	(if (len == 0) { [0, r, 0] } else { [I64.div_trunc_by((mx * r), len), I64.div_trunc_by((my * r), len), I64.div_trunc_by((mz * r), len)] })
})

ico_to_mesh : List(IcoTri), I64 -> Mesh.Mesh
ico_to_mesh = |tris, radius| ({
	n = U64.to_i64_wrap(List.len(tris))
	pair = ico_emit_idx(tris, radius, [], [], 0, 0, n)
	Mesh.mesh_new(list_at_pair_a(pair), list_at_pair_b(pair))
})

ico_emit_idx : List(IcoTri), I64, List(Mesh.Vertex), List(I64), I64, I64, I64 -> IcoPair
ico_emit_idx = |tris, r, verts, indices, vi, i, n| (if (i >= n) { { ip_verts: verts, ip_indices: indices } } else { ({
	tri = (List.get(tris, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	va = ico_make_vert(tri.t_ax, tri.t_ay, tri.t_az, r)
	vb = ico_make_vert(tri.t_bx, tri.t_by, tri.t_bz, r)
	vc = ico_make_vert(tri.t_cx, tri.t_cy, tri.t_cz, r)
	fixed = ico_fix_seam(va, vb, vc)
	fa = (List.get(fixed, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	fb = (List.get(fixed, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
	fc = (List.get(fixed, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))
	new_verts = List.append(List.append(List.append(verts, fa), fb), fc)
	new_indices = List.append(List.append(List.append(indices, vi), (vi + 1)), (vi + 2))
	ico_emit_idx(tris, r, new_verts, new_indices, (vi + 3), (i + 1), n)
}) })

ico_fix_seam : Mesh.Vertex, Mesh.Vertex, Mesh.Vertex -> List(Mesh.Vertex)
ico_fix_seam = |a, b, c| ({
	pa = ico_fix_pole(a, b, c)
	pb = ico_fix_pole(b, a, c)
	pc = ico_fix_pole(c, a, b)
	ua = pa.vu
	ub = pb.vu
	uc = pc.vu
	max_u = gc_max3(ua, ub, uc)
	min_u = gc_min3(ua, ub, uc)
	(if ((max_u - min_u) > 500) { ({
		fa = (if ((max_u - ua) > 500) { ico_wrap_u(pa) } else { pa })
		fb = (if ((max_u - ub) > 500) { ico_wrap_u(pb) } else { pb })
		fc = (if ((max_u - uc) > 500) { ico_wrap_u(pc) } else { pc })
		[fa, fb, fc]
	}) } else { [pa, pb, pc] })
})

ico_fix_pole : Mesh.Vertex, Mesh.Vertex, Mesh.Vertex -> Mesh.Vertex
ico_fix_pole = |v, n1, n2| ({
	any = (if (v.vn_y > 950) { 1 } else { (if (v.vn_y < (-950)) { 1 } else { 0 }) })
	(if (any == 1) { ({
		avg_u = I64.div_trunc_by((n1.vu + n2.vu), 2)
		Mesh.vertex(v.vp_x, v.vp_y, v.vp_z, v.vn_x, v.vn_y, v.vn_z, avg_u, v.vv, v.v_color)
	}) } else { v })
})

ico_wrap_u : Mesh.Vertex -> Mesh.Vertex
ico_wrap_u = |v| Mesh.vertex(v.vp_x, v.vp_y, v.vp_z, v.vn_x, v.vn_y, v.vn_z, (v.vu + 1000), v.vv, v.v_color)

gc_max3 : I64, I64, I64 -> I64
gc_max3 = |a, b, c| (if (a > b) { (if (a > c) { a } else { c }) } else { (if (b > c) { b } else { c }) })

gc_min3 : I64, I64, I64 -> I64
gc_min3 = |a, b, c| (if (a < b) { (if (a < c) { a } else { c }) } else { (if (b < c) { b } else { c }) })

list_at_pair_a : IcoPair -> List(Mesh.Vertex)
list_at_pair_a = |p| p.ip_verts

list_at_pair_b : IcoPair -> List(I64)
list_at_pair_b = |p| p.ip_indices

ico_make_vert : I64, I64, I64, I64 -> Mesh.Vertex
ico_make_vert = |x, y, z, _r| ({
	len = MathLib.math_isqrt((((x * x) + (y * y)) + (z * z)))
	nx = (if (len == 0) { 0 } else { I64.div_trunc_by((x * 1000), len) })
	ny = (if (len == 0) { 1000 } else { I64.div_trunc_by((y * 1000), len) })
	nz = (if (len == 0) { 0 } else { I64.div_trunc_by((z * 1000), len) })
	lat_deg = gc_asin_deg(ny)
	lon_deg = gc_atan2_deg(nz, nx)
	u = I64.div_trunc_by(((lon_deg + 180) * 1000), 360)
	v = I64.div_trunc_by(((lat_deg + 90) * 1000), 180)
	color = earth_color(lat_deg, lon_deg)
	Mesh.vertex(x, y, z, nx, ny, nz, u, v, color)
})

gc_asin_deg : I64 -> I64
gc_asin_deg = |x| ({
	clamped = gc_clamp(x, (-1000), 1000)
	cos_part = MathLib.math_isqrt((1000000 - (clamped * clamped)))
	mrad = gc_atan2_mrad(clamped, cos_part)
	I64.div_trunc_by((mrad * 180), 3141)
})

gc_atan2_deg : I64, I64 -> I64
gc_atan2_deg = |y, x| ({
	mrad = gc_atan2_mrad(y, x)
	I64.div_trunc_by((mrad * 180), 3141)
})

gc_atan2_mrad : I64, I64 -> I64
gc_atan2_mrad = |y, x| (if (x == 0) { (if (y > 0) { 1571 } else { (if (y < 0) { (-1571) } else { 0 }) }) } else { ({
	r = MathLib.math_isqrt(((x * x) + (y * y)))
	denom = (r + x)
	(if (denom <= 0) { (if (y >= 0) { 3141 } else { (-3141) }) } else { ({
		ay = (if (y < 0) { (0 - y) } else { y })
		(if (denom >= ay) { ({
			t = I64.div_trunc_by((y * 1000), (denom + 1))
			(2 * gc_atan_poly(t))
		}) } else { ({
			inv = I64.div_trunc_by((denom * 1000), (ay + 1))
			a = (1571 - gc_atan_poly(inv))
			(if (y >= 0) { (2 * a) } else { (0 - (2 * a)) })
		}) })
	}) })
}) })

gc_atan_poly : I64 -> I64
gc_atan_poly = |t| ({
	neg = (t < 0)
	at = (if neg { (0 - t) } else { t })
	t2 = I64.div_trunc_by((at * at), 1000)
	result = I64.div_trunc_by((at * (15000 + (4 * t2))), (15000 + (9 * t2)))
	(if neg { (0 - result) } else { result })
})

ico_base_tris : I64 -> List(IcoTri)
ico_base_tris = |r| ({
	tr = I64.to_f64(I64.div_trunc_by((851 * r), 1000))
	orad = I64.to_f64(I64.div_trunc_by((526 * r), 1000))
	v0 = Quaternion.vec3_new((-orad), tr, 0.0)
	v1 = Quaternion.vec3_new(orad, tr, 0.0)
	v2 = Quaternion.vec3_new((-orad), (-tr), 0.0)
	v3 = Quaternion.vec3_new(orad, (-tr), 0.0)
	v4 = Quaternion.vec3_new(0.0, (-orad), tr)
	v5 = Quaternion.vec3_new(0.0, orad, tr)
	v6 = Quaternion.vec3_new(0.0, (-orad), (-tr))
	v7 = Quaternion.vec3_new(0.0, orad, (-tr))
	v8 = Quaternion.vec3_new(tr, 0.0, (-orad))
	v9 = Quaternion.vec3_new(tr, 0.0, orad)
	v10 = Quaternion.vec3_new((-tr), 0.0, (-orad))
	v11 = Quaternion.vec3_new((-tr), 0.0, orad)
	[ico_tri_from(v0, v11, v5), ico_tri_from(v0, v5, v1), ico_tri_from(v0, v1, v7), ico_tri_from(v0, v7, v10), ico_tri_from(v0, v10, v11), ico_tri_from(v1, v5, v9), ico_tri_from(v5, v11, v4), ico_tri_from(v11, v10, v2), ico_tri_from(v10, v7, v6), ico_tri_from(v7, v1, v8), ico_tri_from(v3, v9, v4), ico_tri_from(v3, v4, v2), ico_tri_from(v3, v2, v6), ico_tri_from(v3, v6, v8), ico_tri_from(v3, v8, v9), ico_tri_from(v4, v9, v5), ico_tri_from(v2, v4, v11), ico_tri_from(v6, v2, v10), ico_tri_from(v8, v6, v7), ico_tri_from(v9, v8, v1)]
})

ico_tri_from : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3 -> IcoTri
ico_tri_from = |a, b, c| { t_ax: F64.to_i64_wrap(a.vx), t_ay: F64.to_i64_wrap(a.vy), t_az: F64.to_i64_wrap(a.vz), t_bx: F64.to_i64_wrap(b.vx), t_by: F64.to_i64_wrap(b.vy), t_bz: F64.to_i64_wrap(b.vz), t_cx: F64.to_i64_wrap(c.vx), t_cy: F64.to_i64_wrap(c.vy), t_cz: F64.to_i64_wrap(c.vz) }

earth_color : I64, I64 -> I64
earth_color = |lat, lon| ({
	base = (if (lat > 72) { 15792383 } else { (if (lat < (-67)) { 15529215 } else { (if (lat > 65) { 14740730 } else { (if (lat < (-60)) { 14215416 } else { (if earth_is_land(lat, lon) { earth_land_color(lat, lon) } else { earth_ocean_color(lat) }) }) }) }) })
	cloud = cloud_cover(lat, lon)
	(if (cloud > 0) { cloud_blend(base, cloud) } else { base })
})

cloud_cover : I64, I64 -> I64
cloud_cover = |lat, lon| ({
	h1 = gc_hash(I64.div_trunc_by(lat, 6), I64.div_trunc_by(lon, 10))
	h2 = gc_hash((I64.div_trunc_by(lat, 14) + 37), (I64.div_trunc_by(lon, 20) + 53))
	h3 = gc_hash((I64.div_trunc_by(lat, 3) + 71), (I64.div_trunc_by(lon, 5) + 97))
	band = gc_cloud_band(lat)
	noise = I64.div_trunc_by(((h1 + h2) + h3), 3)
	cov = I64.div_trunc_by((noise * band), 255)
	(if (cov > 500) { gc_clamp(I64.div_trunc_by(((cov - 500) * 255), 500), 0, 200) } else { 0 })
})

gc_cloud_band : I64 -> I64
gc_cloud_band = |lat| ({
	abs_lat = (if (lat < 0) { (0 - lat) } else { lat })
	(if (abs_lat < 10) { 900 } else { (if (abs_lat < 20) { 500 } else { (if (abs_lat < 35) { 700 } else { (if (abs_lat < 55) { 800 } else { 600 }) }) }) })
})

gc_hash : I64, I64 -> I64
gc_hash = |a, b| ({
	x = ((((a * 12289) + (b * 51349)) + 32749) * 65537)
	y = (if (x < 0) { (0 - x) } else { x })
	z = I64.div_trunc_by(y, 256)
	(z - (I64.div_trunc_by(z, 256) * 256))
})

cloud_blend : I64, I64 -> I64
cloud_blend = |base, amount| ({
	br = I64.div_trunc_by(base, 65536)
	bg = (I64.div_trunc_by(base, 256) - (br * 256))
	bb = (base - (I64.div_trunc_by(base, 256) * 256))
	r = gc_clamp((br + I64.div_trunc_by(((255 - br) * amount), 255)), 0, 255)
	g = gc_clamp((bg + I64.div_trunc_by(((255 - bg) * amount), 255)), 0, 255)
	b = gc_clamp((bb + I64.div_trunc_by(((255 - bb) * amount), 255)), 0, 255)
	(((r * 65536) + (g * 256)) + b)
})

earth_land_color : I64, I64 -> I64
earth_land_color = |lat, _lon| ({
	abs_lat = (if (lat < 0) { (0 - lat) } else { lat })
	(if (abs_lat > 58) { 10535064 } else { (if (abs_lat > 48) { 4888632 } else { (if (abs_lat > 38) { 6990928 } else { (if (abs_lat > 25) { 13152360 } else { (if (abs_lat > 15) { 6336584 } else { 3708976 }) }) }) }) })
})

earth_ocean_color : I64 -> I64
earth_ocean_color = |lat| ({
	abs_lat = (if (lat < 0) { (0 - lat) } else { lat })
	(if (abs_lat > 55) { 3698872 } else { (if (abs_lat > 35) { 2119864 } else { 1593536 }) })
})

earth_is_land : I64, I64 -> Bool
earth_is_land = |lat, lon| (if earth_na(lat, lon) { True } else { (if earth_sa(lat, lon) { True } else { (if earth_eu(lat, lon) { True } else { (if earth_af(lat, lon) { True } else { (if earth_as(lat, lon) { True } else { (if earth_oc(lat, lon) { True } else { False }) }) }) }) }) })

earth_na : I64, I64 -> Bool
earth_na = |lat, lon| (if earth_in_rect(lat, lon, 50, 72, (-145), (-55)) { True } else { (if earth_in_rect(lat, lon, 48, 55, (-130), (-55)) { True } else { (if earth_in_rect(lat, lon, 40, 50, (-128), (-66)) { True } else { (if earth_in_rect(lat, lon, 30, 40, (-122), (-75)) { True } else { (if earth_in_rect(lat, lon, 25, 30, (-115), (-80)) { True } else { (if earth_in_rect(lat, lon, 30, 48, (-75), (-52)) { True } else { (if earth_in_rect(lat, lon, 15, 25, (-105), (-80)) { True } else { (if earth_in_rect(lat, lon, 8, 18, (-90), (-77)) { True } else { (if earth_in_rect(lat, lon, 60, 72, (-168), (-140)) { True } else { (if earth_in_rect(lat, lon, 18, 25, (-80), (-72)) { True } else { (if earth_in_rect(lat, lon, 20, 24, (-110), (-105)) { True } else { (if earth_in_rect(lat, lon, 45, 55, (-55), (-52)) { True } else { False }) }) }) }) }) }) }) }) }) }) }) })

earth_sa : I64, I64 -> Bool
earth_sa = |lat, lon| (if earth_in_rect(lat, lon, 0, 12, (-80), (-60)) { True } else { (if earth_in_rect(lat, lon, (-5), 0, (-80), (-50)) { True } else { (if earth_in_rect(lat, lon, (-15), (-5), (-78), (-38)) { True } else { (if earth_in_rect(lat, lon, (-24), (-15), (-70), (-36)) { True } else { (if earth_in_rect(lat, lon, (-34), (-24), (-70), (-48)) { True } else { (if earth_in_rect(lat, lon, (-40), (-34), (-72), (-56)) { True } else { (if earth_in_rect(lat, lon, (-55), (-40), (-74), (-64)) { True } else { (if earth_in_rect(lat, lon, (-22), (-2), (-50), (-35)) { True } else { (if earth_in_rect(lat, lon, (-2), 5, (-52), (-44)) { True } else { (if earth_in_rect(lat, lon, (-10), 0, (-60), (-50)) { True } else { False }) }) }) }) }) }) }) }) }) })

earth_eu : I64, I64 -> Bool
earth_eu = |lat, lon| (if earth_in_rect(lat, lon, 48, 60, (-10), 40) { True } else { (if earth_in_rect(lat, lon, 43, 48, (-9), 30) { True } else { (if earth_in_rect(lat, lon, 60, 72, 5, 30) { True } else { (if earth_in_rect(lat, lon, 55, 65, (-12), 5) { True } else { (if earth_in_rect(lat, lon, 36, 43, (-9), 3) { True } else { (if earth_in_rect(lat, lon, 36, 43, 8, 28) { True } else { (if earth_in_rect(lat, lon, 38, 42, 28, 44) { True } else { (if earth_in_rect(lat, lon, 56, 72, 30, 42) { True } else { (if earth_in_rect(lat, lon, 64, 72, 15, 30) { True } else { (if earth_in_rect(lat, lon, 36, 40, 22, 30) { True } else { False }) }) }) }) }) }) }) }) }) })

earth_af : I64, I64 -> Bool
earth_af = |lat, lon| (if earth_in_rect(lat, lon, 20, 37, (-17), 12) { True } else { (if earth_in_rect(lat, lon, 10, 20, (-17), 18) { True } else { (if earth_in_rect(lat, lon, 4, 10, (-12), 15) { True } else { (if earth_in_rect(lat, lon, 0, 4, 5, 15) { True } else { (if earth_in_rect(lat, lon, (-5), 0, 10, 32) { True } else { (if earth_in_rect(lat, lon, (-15), (-5), 12, 42) { True } else { (if earth_in_rect(lat, lon, 0, 12, 25, 42) { True } else { (if earth_in_rect(lat, lon, 12, 25, 32, 52) { True } else { (if earth_in_rect(lat, lon, (-25), (-15), 20, 40) { True } else { (if earth_in_rect(lat, lon, (-35), (-25), 22, 34) { True } else { (if earth_in_rect(lat, lon, (-12), 0, 42, 48) { True } else { False }) }) }) }) }) }) }) }) }) }) })

earth_as : I64, I64 -> Bool
earth_as = |lat, lon| (if earth_in_rect(lat, lon, 50, 70, 42, 140) { True } else { (if earth_in_rect(lat, lon, 42, 50, 44, 135) { True } else { (if earth_in_rect(lat, lon, 55, 72, 140, 175) { True } else { (if earth_in_rect(lat, lon, 30, 42, 44, 82) { True } else { (if earth_in_rect(lat, lon, 22, 30, 48, 75) { True } else { (if earth_in_rect(lat, lon, 25, 42, 82, 128) { True } else { (if earth_in_rect(lat, lon, 10, 25, 93, 108) { True } else { (if earth_in_rect(lat, lon, 30, 45, 128, 142) { True } else { (if earth_in_rect(lat, lon, (-8), 10, 100, 118) { True } else { (if earth_in_rect(lat, lon, 5, 20, 118, 128) { True } else { (if earth_in_rect(lat, lon, 35, 42, 125, 132) { True } else { False }) }) }) }) }) }) }) }) }) }) })

earth_oc : I64, I64 -> Bool
earth_oc = |lat, lon| (if earth_in_rect(lat, lon, (-28), (-12), 114, 154) { True } else { (if earth_in_rect(lat, lon, (-38), (-28), 115, 150) { True } else { (if earth_in_rect(lat, lon, (-12), (-5), 130, 150) { True } else { (if earth_in_rect(lat, lon, (-47), (-34), 166, 178) { True } else { (if earth_in_rect(lat, lon, (-38), (-34), 145, 178) { True } else { (if earth_in_rect(lat, lon, (-34), (-25), 150, 170) { True } else { False }) }) }) }) }) })

earth_in_rect : I64, I64, I64, I64, I64, I64 -> Bool
earth_in_rect = |lat, lon, lat_lo, lat_hi, lon_lo, lon_hi| ((((lat >= lat_lo) and (lat <= lat_hi)) and (lon >= lon_lo)) and (lon <= lon_hi))

globe_milli : F64 -> I64
globe_milli = |x| F64.to_i64_wrap((x * 1000.0))

globe_frame! : Machine.Machine, I64, Mesh.Mesh, I64, I64, I64 => (Machine.Machine, I64)
globe_frame! = |machine, cmd, sphere, yaw, pitch, dist| ({
	cam = gorbit(yaw, pitch, dist)
	vp = Scene3D.camera3d_vp(cam)
	eye = cam.c3_eye
	light = gnorm(eye)
	globe_draw!(machine, cmd, sphere, vp, light, eye)
})

globe_draw! : Machine.Machine, I64, Mesh.Mesh, Matrix4.Mat4, Quaternion.Vec3, Quaternion.Vec3 => (Machine.Machine, I64)
globe_draw! = |machine, cmd, sphere, vp, light, eye| ({
	(machine1, _wlx) = Machine.port_out_32!(machine, 1028, globe_milli(light.vx))
	(machine2, _wly) = Machine.port_out_32!(machine1, 1029, globe_milli(light.vy))
	(machine3, _wlz) = Machine.port_out_32!(machine2, 1030, globe_milli(light.vz))
	(machine4, _wex) = Machine.port_out_32!(machine3, 1031, globe_milli(light.vx))
	({
		(machine5, machine__2) = gtris!(machine4, sphere, vp, light, eye, cmd, 0, (Mesh.mesh_triangle_count(sphere) * 3), 0)
		globe_fire!(machine5, machine__2)
	})
})

globe_fire! : Machine.Machine, I64 => (Machine.Machine, I64)
globe_fire! = |machine, tri_count| ({
	(machine1, _w1) = Machine.port_out_32!(machine, 1025, 132114)
	(machine2, _w2) = Machine.port_out_32!(machine1, 1026, 0)
	Machine.port_out_32!(machine2, 1024, tri_count)
})

gtris! : Machine.Machine, Mesh.Mesh, Matrix4.Mat4, Quaternion.Vec3, Quaternion.Vec3, I64, I64, I64, I64 => (Machine.Machine, I64)
gtris! = |machine, mesh, vp, light, eye, cmd, i, n, tri_idx| (if (i >= n) { (machine, tri_idx) } else { (if (tri_idx >= 16384) { (machine, tri_idx) } else { ({
	v0 = Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i))
	v1 = Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1)))
	v2 = Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2)))
	p0 = gproj(v0, vp)
	p1 = gproj(v1, vp)
	p2 = gproj(v2, vp)
	area = (((p1.gp_sx - p0.gp_sx) * (p2.gp_sy - p0.gp_sy)) - ((p1.gp_sy - p0.gp_sy) * (p2.gp_sx - p0.gp_sx)))
	(if (area >= 0) { gtris!(machine, mesh, vp, light, eye, cmd, (i + 3), n, tri_idx) } else { ({
		off = (tri_idx * 72)
		c0 = glit_color(v0, light)
		c1 = glit_color(v1, light)
		c2 = glit_color(v2, light)
		(machine1, machine__3) = Machine.store!(machine, cmd, off, p0.gp_sx, 4)
		(machine2, machine__4) = Machine.store!(machine1, cmd, (off + 4), p0.gp_sy, 4)
		(machine3, machine__5) = Machine.store!(machine2, cmd, (off + 8), p1.gp_sx, 4)
		(machine4, machine__6) = Machine.store!(machine3, cmd, (off + 12), p1.gp_sy, 4)
		(machine5, machine__7) = Machine.store!(machine4, cmd, (off + 16), p2.gp_sx, 4)
		(machine6, machine__8) = Machine.store!(machine5, cmd, (off + 20), p2.gp_sy, 4)
		(machine7, machine__9) = Machine.store!(machine6, cmd, (off + 24), c0, 4)
		(machine8, machine__10) = Machine.store!(machine7, cmd, (off + 28), c1, 4)
		(machine9, machine__11) = Machine.store!(machine8, cmd, (off + 32), c2, 4)
		(machine10, machine__12) = Machine.store!(machine9, cmd, (off + 36), p0.gp_depth, 4)
		(machine11, machine__13) = Machine.store!(machine10, cmd, (off + 40), p1.gp_depth, 4)
		(machine12, machine__14) = Machine.store!(machine11, cmd, (off + 44), p2.gp_depth, 4)
		(machine13, machine__15) = Machine.store!(machine12, cmd, (off + 48), v0.vu, 4)
		(machine14, machine__16) = Machine.store!(machine13, cmd, (off + 52), v0.vv, 4)
		(machine15, machine__17) = Machine.store!(machine14, cmd, (off + 56), v1.vu, 4)
		(machine16, machine__18) = Machine.store!(machine15, cmd, (off + 60), v1.vv, 4)
		(machine17, machine__19) = Machine.store!(machine16, cmd, (off + 64), v2.vu, 4)
		(machine18, machine__20) = Machine.store!(machine17, cmd, (off + 68), v2.vv, 4)
		_w = (((((((((((((((((machine__3 + machine__4) + machine__5) + machine__6) + machine__7) + machine__8) + machine__9) + machine__10) + machine__11) + machine__12) + machine__13) + machine__14) + machine__15) + machine__16) + machine__17) + machine__18) + machine__19) + machine__20)
		gtris!(machine18, mesh, vp, light, eye, cmd, (i + 3), n, (tri_idx + 1))
	}) })
}) }) })

gtris_next! : Machine.Machine, I64, Mesh.Mesh, Matrix4.Mat4, Quaternion.Vec3, Quaternion.Vec3, I64, I64, I64, I64 => (Machine.Machine, I64)
gtris_next! = |machine, _w, mesh, vp, light, eye, cmd, i, n, tri_idx| gtris!(machine, mesh, vp, light, eye, cmd, (i + 3), n, (tri_idx + 1))

glit_color : Mesh.Vertex, Quaternion.Vec3 -> I64
glit_color = |_v, _light| 16777215

gproj : Mesh.Vertex, Matrix4.Mat4 -> GProj
gproj = |v, mvp| ({
	clip = Matrix4.mat4_transform_vec4(mvp, { v4x: I64.to_f64(v.vp_x), v4y: I64.to_f64(v.vp_y), v4z: I64.to_f64(v.vp_z), v4w: 1.0 })
	(if (clip.v4w <= 0.0) { { gp_sx: (-9999), gp_sy: (-9999), gp_depth: 999999 } } else { ({
		ndc_x = (clip.v4x / clip.v4w)
		ndc_y = (clip.v4y / clip.v4w)
		ndc_z = (clip.v4z / clip.v4w)
		half_w = I64.to_f64(I64.div_trunc_by(sw, 2))
		half_h = I64.to_f64(I64.div_trunc_by(sh, 2))
		{ gp_sx: F64.to_i64_wrap((half_w + (ndc_x * half_w))), gp_sy: F64.to_i64_wrap((half_h - (ndc_y * half_h))), gp_depth: F64.to_i64_wrap(((ndc_z + 1.0) * 500000.0)) }
	}) })
})

globe_loop! : Machine.Machine, I64, Mesh.Mesh, I64, I64, I64, I64 => (Machine.Machine, Str)
globe_loop! = |machine, cmd, sphere, yaw, pitch, dist, frame| ({
	(machine1, _dummy) = Machine.port_in_byte!(machine, 96)
	({
		(machine2, sc) = Machine.load!(machine1, kb_addr, 0, 1)
		(machine3, mflags) = Machine.load!(machine2, mouse_addr, 0, 1)
		(machine4, mdx) = Machine.load!(machine3, mouse_addr, 1, 1)
		(machine5, mdy) = Machine.load!(machine4, mouse_addr, 2, 1)
		(machine6, _mc0) = Machine.store!(machine5, mouse_addr, 0, 0, 1)
		(machine7, _mc1) = Machine.store!(machine6, mouse_addr, 1, 0, 1)
		(machine8, _mc2) = Machine.store!(machine7, mouse_addr, 2, 0, 1)
		(machine9, _ack) = Machine.store!(machine8, kb_addr, 0, 0, 1)
		mouse_dx = (if (mdx > 127) { (mdx - 256) } else { mdx })
		mouse_dy = (if (mdy > 127) { (mdy - 256) } else { mdy })
		dragging = (I64.div_trunc_by(mflags, 1) - (I64.div_trunc_by(mflags, 2) * 2))
		yaw2 = (if (dragging == 1) { (yaw - (mouse_dx * 8)) } else { (yaw + 3) })
		pitch2 = (if (dragging == 1) { gc_clamp((pitch + (mouse_dy * 8)), (-1400), 1400) } else { pitch })
		(if (sc == 16) { (machine9, "quit") } else { (if (sc == 1) { (machine9, "quit") } else { (if (sc == 18) { globe_regen!(machine9, cmd, sphere, PkEarth, 42, yaw2, pitch2, dist, frame) } else { (if (sc == 50) { globe_regen!(machine9, cmd, sphere, PkMars, 77, yaw2, pitch2, dist, frame) } else { (if (sc == 19) { globe_regen!(machine9, cmd, sphere, PkRandom, ((frame * 7) + 1337), yaw2, pitch2, dist, frame) } else { ({
			y3 = (if (sc == 75) { (yaw2 - 120) } else { (if (sc == 77) { (yaw2 + 120) } else { yaw2 }) })
			p2 = (if (sc == 72) { gc_clamp((pitch2 + 60), (-1400), 1400) } else { (if (sc == 80) { gc_clamp((pitch2 - 60), (-1400), 1400) } else { pitch2 }) })
			d2 = (if (sc == 78) { gc_clamp((dist - 300), 4000, 25000) } else { (if (sc == 74) { gc_clamp((dist + 300), 4000, 25000) } else { dist }) })
			globe_step!(machine9, cmd, sphere, y3, p2, d2, frame)
		}) }) }) }) }) })
	})
})

globe_regen! : Machine.Machine, I64, Mesh.Mesh, TerrainGen.PlanetKind, I64, I64, I64, I64, I64 => (Machine.Machine, Str)
globe_regen! = |machine, cmd, sphere, kind, seed, yaw, pitch, dist, frame| ({
	(machine1, _gen) = TerrainGen.tg_generate!(machine, kind, seed)
	globe_loop!(machine1, cmd, sphere, yaw, pitch, dist, (frame + 1))
})

globe_step! : Machine.Machine, I64, Mesh.Mesh, I64, I64, I64, I64 => (Machine.Machine, Str)
globe_step! = |machine, cmd, sphere, yaw, pitch, dist, frame| ({
	(machine1, hp) = Machine.mark(machine)
	globe_step_done!(machine1, cmd, sphere, yaw, pitch, dist, frame, hp)
})

globe_step_done! : Machine.Machine, I64, Mesh.Mesh, I64, I64, I64, I64, I64 => (Machine.Machine, Str)
globe_step_done! = |machine, cmd, sphere, yaw, pitch, dist, frame, hp| ({
	(machine1, _w) = globe_frame!(machine, cmd, sphere, yaw, pitch, dist)
	({
		(machine2, _restored) = Machine.release(machine1, hp)
		globe_loop!(machine2, cmd, sphere, yaw, pitch, dist, (frame + 1))
	})
})

gorbit : I64, I64, I64 -> Scene3D.Camera3D
gorbit = |yaw, pitch, dist| ({
	sy = gc_sin(gc_wrap(yaw))
	cy = gc_cos(gc_wrap(yaw))
	sp = gc_sin(gc_wrap(pitch))
	cp = gc_cos(gc_wrap(pitch))
	Scene3D.camera3d_new(Quaternion.vec3_new(I64.to_f64(I64.div_trunc_by(((sy * cp) * dist), 1000000)), I64.to_f64(I64.div_trunc_by((sp * dist), 1000)), I64.to_f64(I64.div_trunc_by(((cy * cp) * dist), 1000000))), Quaternion.vec3_zero, 0.785)
})

gnorm : Quaternion.Vec3 -> Quaternion.Vec3
gnorm = |v| Matrix4.mat4_v3_normalize(v)

gc_sin : I64 -> I64
gc_sin = |raw| ({
	a = gc_wrap(raw)
	(if (a <= 1570) { gc_sin_core(a) } else { (if (a <= 3141) { gc_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - gc_sin_core((a - 3141))) } else { (0 - gc_sin_core((6283 - a))) }) }) })
})

gc_cos : I64 -> I64
gc_cos = |raw| gc_sin((raw + 1570))

gc_sin_core : I64 -> I64
gc_sin_core = |x| ({
	x2 = I64.div_trunc_by((x * x), 1000)
	x3 = I64.div_trunc_by((x2 * x), 1000)
	x5 = I64.div_trunc_by((x3 * x2), 1000)
	((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
})

gc_wrap : I64 -> I64
gc_wrap = |a| ({
	m = (a - (I64.div_trunc_by(a, 6283) * 6283))
	(if (m < 0) { (m + 6283) } else { m })
})

gc_clamp : I64, I64, I64 -> I64
gc_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Device.Port", "Gpu.Compute", "Gpu.Memory"])
	(machine1, machine__1) = globe_main!(machine, gpu_cmd)
	result = machine__1
	line!(result)
	Machine.halt!(machine1)
	Ok({})
}
