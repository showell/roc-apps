# Raytracer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Geometry
import Quaternion
import Rasterizer

Raytracer :: [].{
	Material : { mat_color : Color.Rgb, mat_diffuse : I64, mat_specular : I64, mat_shininess : I64 }
	RtSphere : { rt_center : Quaternion.Vec3, rt_radius : F64, rt_mat : Raytracer.Material }
	RtPlane : { rt_point : Quaternion.Vec3, rt_normal : Quaternion.Vec3, rt_mat : Raytracer.Material }
	SceneObj : [ObjSphere(Raytracer.RtSphere), ObjPlane(Raytracer.RtPlane)]
	RtScene : { rt_objects : List(Raytracer.SceneObj), rt_light_pos : Quaternion.Vec3, rt_light_color : Color.Rgb, rt_ambient : I64, rt_bg : Color.Rgb }
	RtHit : { rt_did_hit : Bool, rt_dist : F64, rt_pos : Quaternion.Vec3, rt_norm : Quaternion.Vec3, rt_material : Raytracer.Material }
	RtCamera : { cam_origin : Quaternion.Vec3, cam_fov : I64 }

	scene_new : Quaternion.Vec3, Color.Rgb, I64, Color.Rgb -> Raytracer.RtScene
	scene_new = |light, light_col, ambient, bg| { rt_objects: [], rt_light_pos: light, rt_light_color: light_col, rt_ambient: ambient, rt_bg: bg }

	scene_add : Raytracer.RtScene, Raytracer.SceneObj -> Raytracer.RtScene
	scene_add = |s, obj| { rt_objects: List.append(s.rt_objects, obj), rt_light_pos: s.rt_light_pos, rt_light_color: s.rt_light_color, rt_ambient: s.rt_ambient, rt_bg: s.rt_bg }

	rt_mat_new : Color.Rgb, I64, I64, I64 -> Raytracer.Material
	rt_mat_new = |color, diff, spec, shine| { mat_color: color, mat_diffuse: diff, mat_specular: spec, mat_shininess: shine }

	mat_matte : Color.Rgb -> Raytracer.Material
	mat_matte = |color| { mat_color: color, mat_diffuse: 800, mat_specular: 200, mat_shininess: 8 }

	mat_shiny : Color.Rgb -> Raytracer.Material
	mat_shiny = |color| { mat_color: color, mat_diffuse: 500, mat_specular: 700, mat_shininess: 32 }

	rt_no_hit : Raytracer.RtHit
	rt_no_hit = { rt_did_hit: False, rt_dist: 999999.0, rt_pos: Quaternion.vec3_zero, rt_norm: Quaternion.vec3_zero, rt_material: mat_matte(Color.rgb_black) }

	rt_intersect_obj : Geometry.Ray3, Raytracer.SceneObj -> Raytracer.RtHit
	rt_intersect_obj = |ray, obj| (match obj {
		ObjSphere(s) => rt_intersect_sphere(ray, s)
		ObjPlane(p) => rt_intersect_plane(ray, p)
	})

	rt_intersect_sphere : Geometry.Ray3, Raytracer.RtSphere -> Raytracer.RtHit
	rt_intersect_sphere = |ray, s| ({
		hit = Geometry.ray3_sphere(ray, s.rt_center, s.rt_radius)
		(if hit.rh3_hit { ({
			norm = rt_normalize(Quaternion.vec3_subtract(hit.rh3_point, s.rt_center))
			{ rt_did_hit: True, rt_dist: hit.rh3_t, rt_pos: hit.rh3_point, rt_norm: norm, rt_material: s.rt_mat }
		}) } else { rt_no_hit })
	})

	rt_intersect_plane : Geometry.Ray3, Raytracer.RtPlane -> Raytracer.RtHit
	rt_intersect_plane = |ray, p| ({
		hit = Geometry.ray3_plane(ray, p.rt_point, p.rt_normal)
		(if hit.rh3_hit { { rt_did_hit: True, rt_dist: hit.rh3_t, rt_pos: hit.rh3_point, rt_norm: p.rt_normal, rt_material: p.rt_mat } } else { rt_no_hit })
	})

	rt_trace : Geometry.Ray3, Raytracer.RtScene -> Raytracer.RtHit
	rt_trace = |ray, scene| ({
		objs = scene.rt_objects
		i = rt_nearest(ray, objs, 0, U64.to_i64_wrap(List.len(objs)), (0 - 1), rt_no_hit.rt_dist)
		(if (i < 0) { rt_no_hit } else { rt_intersect_obj(ray, (List.get(objs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) })
	})

	rt_nearest : Geometry.Ray3, List(Raytracer.SceneObj), I64, I64, I64, F64 -> I64
	rt_nearest = |ray, objs, i, n, best, best_dist| (if (i >= n) { best } else { ({
		d = rt_obj_dist(ray, (List.get(objs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if ((d >= 0.0) and (d < best_dist)) { rt_nearest(ray, objs, (i + 1), n, i, d) } else { rt_nearest(ray, objs, (i + 1), n, best, best_dist) })
	}) })

	rt_obj_dist : Geometry.Ray3, Raytracer.SceneObj -> F64
	rt_obj_dist = |ray, obj| (match obj {
		ObjSphere(s) => rt_hit_dist(Geometry.ray3_sphere(ray, s.rt_center, s.rt_radius))
		ObjPlane(p) => rt_hit_dist(Geometry.ray3_plane(ray, p.rt_point, p.rt_normal))
	})

	rt_hit_dist : Geometry.RayHit3 -> F64
	rt_hit_dist = |hit| (if hit.rh3_hit { hit.rh3_t } else { (0.0 - 1.0) })

	rt_shade : Raytracer.RtHit, Raytracer.RtScene, Quaternion.Vec3 -> Color.Rgb
	rt_shade = |hit, scene, ray_dir| (if hit.rt_did_hit { ({
		to_light = rt_normalize(Quaternion.vec3_subtract(scene.rt_light_pos, hit.rt_pos))
		n_dot_l = Quaternion.vec3_dot(hit.rt_norm, to_light)
		diffuse = (if (n_dot_l > 0.0) { n_dot_l } else { 0.0 })
		reflect = rt_reflect(Quaternion.vec3_scale(to_light, (-1.0)), hit.rt_norm)
		r_dot_v = Quaternion.vec3_dot(reflect, Quaternion.vec3_scale(ray_dir, (-1.0)))
		spec_raw = (if (r_dot_v > 0.0) { r_dot_v } else { 0.0 })
		specular = rt_pow_real(spec_raw, hit.rt_material.mat_shininess)
		mat = hit.rt_material
		amb = I64.to_f64(scene.rt_ambient)
		diff_contrib = (I64.to_f64(mat.mat_diffuse) * diffuse)
		spec_contrib = (I64.to_f64(mat.mat_specular) * specular)
		intensity = ((amb + diff_contrib) + spec_contrib)
		capped = (if (intensity > 1000.0) { 1000 } else { F64.to_i64_wrap(intensity) })
		Color.rgb_scale(mat.mat_color, capped)
	}) } else { scene.rt_bg })

	rt_reflect : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	rt_reflect = |incoming, normal| ({
		d = Quaternion.vec3_dot(incoming, normal)
		Quaternion.vec3_subtract(incoming, Quaternion.vec3_scale(normal, (2.0 * d)))
	})

	rt_camera_new : Quaternion.Vec3, I64 -> Raytracer.RtCamera
	rt_camera_new = |origin, fov| { cam_origin: origin, cam_fov: fov }

	rt_pixel_ray : Raytracer.RtCamera, I64, I64, I64, I64 -> Geometry.Ray3
	rt_pixel_ray = |cam, px, py, width, height| ({
		aspect = (I64.to_f64(width) / I64.to_f64(height))
		half_fov = (I64.to_f64(cam.cam_fov) / 2000.0)
		nx = ((((2.0 * I64.to_f64(px)) - I64.to_f64(width)) * half_fov) / I64.to_f64(width))
		ny = (((I64.to_f64(height) - (2.0 * I64.to_f64(py))) * half_fov) / I64.to_f64(height))
		dir = rt_normalize(Quaternion.vec3_new((nx * aspect), ny, 1.0))
		Geometry.ray3_new(cam.cam_origin, dir)
	})

	rt_render : Raytracer.RtScene, Raytracer.RtCamera, I64, I64 -> Rasterizer.Framebuf
	rt_render = |scene, cam, width, height| ({
		fb = Rasterizer.fb_new(width, height, Color.rgb_to_packed(scene.rt_bg))
		rt_render_loop(scene, cam, fb, width, height, 0, 0)
	})

	rt_render_loop : Raytracer.RtScene, Raytracer.RtCamera, Rasterizer.Framebuf, I64, I64, I64, I64 -> Rasterizer.Framebuf
	rt_render_loop = |scene, cam, fb, w, h, x, y| (if (y >= h) { fb } else { (if (x >= w) { rt_render_loop(scene, cam, fb, w, h, 0, (y + 1)) } else { ({
		ray = rt_pixel_ray(cam, x, y, w, h)
		hit = rt_trace(ray, scene)
		color = rt_shade(hit, scene, ray.r3_dir)
		fb2 = Rasterizer.fb_set(fb, x, y, Color.rgb_to_packed(color))
		rt_render_loop(scene, cam, fb2, w, h, (x + 1), y)
	}) }) })

	rt_normalize : Quaternion.Vec3 -> Quaternion.Vec3
	rt_normalize = |v| ({
		len = Geometry.geo_sqrt((((v.vx * v.vx) + (v.vy * v.vy)) + (v.vz * v.vz)))
		(if (F64.to_bits(len) == F64.to_bits(0.0)) { Quaternion.vec3_zero } else { Quaternion.vec3_new((v.vx / len), (v.vy / len), (v.vz / len)) })
	})

	rt_pow_real : F64, I64 -> F64
	rt_pow_real = |base, exp| rt_pow_loop_real(base, exp, 1.0)

	rt_pow_loop_real : F64, I64, F64 -> F64
	rt_pow_loop_real = |base, exp, acc| (if (exp <= 0) { acc } else { rt_pow_loop_real(base, (exp - 1), (acc * base)) })

	eq_SceneObj : Raytracer.SceneObj, Raytracer.SceneObj -> Bool
	eq_SceneObj = |ex, ey| (match ex {
		ObjSphere(exf0) => (match ey {
			ObjSphere(eyf0) => (exf0 == eyf0)
			_ => False
		})
		ObjPlane(exf0) => (match ey {
			ObjPlane(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
