# TerrainGen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Cce
import Machine

TerrainGen :: [].{
	PlanetKind : [PkEarth, PkMars, PkRandom]

	tex_w : I64
	tex_w = 512

	tex_h : I64
	tex_h = 256

	tex_buf_addr : I64
	tex_buf_addr = 1879048192

	tex_path_addr : I64
	tex_path_addr = 1877999616

	tg_load_file! : Machine.Machine, Str, I64, I64 => (Machine.Machine, I64)
	tg_load_file! = |machine, path, dest, path_buf| ({
		(machine1, _written) = tg_write_path!(machine, path, path_buf, 0)
		tg_load_fire!(machine1, path_buf, dest)
	})

	tg_load_fire! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	tg_load_fire! = |machine, path_buf, dest| ({
		(machine1, _w1) = Machine.port_out_32!(machine, 1036, path_buf)
		(machine2, _w2) = Machine.port_out_32!(machine1, 1037, dest)
		(machine3, _w3) = Machine.port_out_32!(machine2, 1047, 0)
		Machine.port_in_32!(machine3, 1038)
	})

	tg_write_path! : Machine.Machine, Str, I64, I64 => (Machine.Machine, I64)
	tg_write_path! = |machine, s, addr, i| (if (i >= Cce.length(s)) { Machine.store!(machine, addr, i, 0, 1) } else { ({
		ch = CCE.to_unicode(Cce.at_or_crash(s, i))
		(machine1, _w) = Machine.store!(machine, addr, i, ch, 1)
		tg_write_path!(machine1, s, addr, (i + 1))
	}) })

	tg_load_earth_image! : Machine.Machine => (Machine.Machine, I64)
	tg_load_earth_image! = |machine| ({
		(machine1, sz) = tg_load_file!(machine, "apps/globe/earth-texture.raw", tex_buf_addr, tex_path_addr)
		(if (sz > 0) { tg_commit_earth!(machine1, sz) } else { (machine1, 0) })
	})

	tg_commit_earth! : Machine.Machine, I64 => (Machine.Machine, I64)
	tg_commit_earth! = |machine, sz| ({
		w = (if (sz == ((2048 * 1024) * 3)) { 2048 } else { (if (sz == ((4096 * 2048) * 3)) { 4096 } else { (if (sz == ((1024 * 512) * 3)) { 1024 } else { 512 }) }) })
		h = I64.div_trunc_by(sz, (w * 3))
		tg_upload_tex!(machine, tex_buf_addr, w, h, sz)
	})

	tg_upload_tex! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	tg_upload_tex! = |machine, addr, w, h, ret| ({
		(machine1, _wa) = Machine.port_out_32!(machine, 1032, addr)
		(machine2, _wb) = Machine.port_out_32!(machine1, 1033, w)
		(machine3, _wc) = Machine.port_out_32!(machine2, 1034, h)
		(machine4, _wd) = Machine.port_out_32!(machine3, 1035, 0)
		(machine4, ret)
	})

	tg_hash : I64, I64 -> I64
	tg_hash = |a, b| ({
		x = ((((a * 12289) + (b * 51349)) + 32749) * 65537)
		y = (if (x < 0) { (0 - x) } else { x })
		z = I64.div_trunc_by(y, 1000)
		(z - (I64.div_trunc_by(z, 1000) * 1000))
	})

	tg_noise : I64, I64 -> I64
	tg_noise = |x, y| ({
		ix = (if (x >= 0) { I64.div_trunc_by(x, 1000) } else { (I64.div_trunc_by(x, 1000) - 1) })
		iy = (if (y >= 0) { I64.div_trunc_by(y, 1000) } else { (I64.div_trunc_by(y, 1000) - 1) })
		fx = (x - (ix * 1000))
		fy = (y - (iy * 1000))
		sx = I64.div_trunc_by(((fx * fx) * (3000 - (2 * fx))), 1000000)
		sy = I64.div_trunc_by(((fy * fy) * (3000 - (2 * fy))), 1000000)
		c00 = tg_hash(ix, iy)
		c10 = tg_hash((ix + 1), iy)
		c01 = tg_hash(ix, (iy + 1))
		c11 = tg_hash((ix + 1), (iy + 1))
		x0 = (I64.div_trunc_by((c00 * (1000 - sx)), 1000) + I64.div_trunc_by((c10 * sx), 1000))
		x1 = (I64.div_trunc_by((c01 * (1000 - sx)), 1000) + I64.div_trunc_by((c11 * sx), 1000))
		(I64.div_trunc_by((x0 * (1000 - sy)), 1000) + I64.div_trunc_by((x1 * sy), 1000))
	})

	tg_fbm : I64, I64, I64 -> I64
	tg_fbm = |x, y, seed| ({
		n1 = tg_noise((x + (seed * 137)), (y + (seed * 251)))
		n2 = tg_noise((((x * 2) + (seed * 337)) + 50000), (((y * 2) + (seed * 449)) + 50000))
		n3 = tg_noise((((x * 4) + (seed * 541)) + 100000), (((y * 4) + (seed * 643)) + 100000))
		n4 = tg_noise((((x * 8) + (seed * 751)) + 200000), (((y * 8) + (seed * 853)) + 200000))
		(((I64.div_trunc_by((n1 * 500), 1000) + I64.div_trunc_by((n2 * 250), 1000)) + I64.div_trunc_by((n3 * 125), 1000)) + I64.div_trunc_by((n4 * 62), 1000))
	})

	tg_earth_pixel : I64, I64, I64 -> I64
	tg_earth_pixel = |lat, lon, seed| ({
		elev = tg_fbm((lon * 3), (lat * 3), seed)
		moisture = tg_fbm(((lon * 2) + 70000), ((lat * 2) + 30000), (seed + 17))
		abs_lat = (if (lat < 0) { (0 - lat) } else { lat })
		temp = ((1000 - I64.div_trunc_by((abs_lat * 1000), 90)) - I64.div_trunc_by(elev, 4))
		(if (abs_lat > 75) { tg_ice_color(elev) } else { (if (elev < 380) { tg_ocean_color(elev, temp) } else { (if (elev < 400) { tg_shore_color(elev, moisture) } else { tg_land_biome(elev, moisture, temp) }) }) })
	})

	tg_ice_color : I64 -> I64
	tg_ice_color = |elev| ({
		v = (220 + I64.div_trunc_by((elev * 35), 1000))
		(((tg_clamp8(v) * 65536) + (tg_clamp8((v + 5)) * 256)) + tg_clamp8((v + 10)))
	})

	tg_ocean_color : I64, I64 -> I64
	tg_ocean_color = |elev, temp| ({
		depth = (380 - elev)
		r = tg_clamp8((10 + I64.div_trunc_by(depth, 20)))
		g = tg_clamp8(((40 + I64.div_trunc_by(temp, 20)) + I64.div_trunc_by(depth, 15)))
		b = tg_clamp8((120 + I64.div_trunc_by(temp, 8)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_shore_color : I64, I64 -> I64
	tg_shore_color = |_elev, moisture| ({
		r = tg_clamp8((180 + I64.div_trunc_by(moisture, 20)))
		g = tg_clamp8((170 + I64.div_trunc_by(moisture, 15)))
		b = tg_clamp8(120)
		(((r * 65536) + (g * 256)) + b)
	})

	tg_land_biome : I64, I64, I64 -> I64
	tg_land_biome = |elev, moisture, temp| (if (elev > 750) { tg_mountain_color(elev) } else { (if (temp < 300) { tg_tundra_color(elev, moisture) } else { (if (moisture > 600) { tg_forest_color(elev, temp) } else { (if (temp > 700) { (if (moisture < 300) { tg_desert_color(elev, moisture) } else { tg_savanna_color(elev, moisture) }) } else { tg_grassland_color(elev, moisture) }) }) }) })

	tg_mountain_color : I64 -> I64
	tg_mountain_color = |elev| (if (elev > 900) { ({
		v = (230 + I64.div_trunc_by(elev, 20))
		(((tg_clamp8(v) * 65536) + (tg_clamp8(v) * 256)) + tg_clamp8(v))
	}) } else { ({
		g = tg_clamp8((100 + I64.div_trunc_by(elev, 10)))
		(((tg_clamp8((80 + I64.div_trunc_by(elev, 15))) * 65536) + (g * 256)) + tg_clamp8((70 + I64.div_trunc_by(elev, 20))))
	}) })

	tg_tundra_color : I64, I64 -> I64
	tg_tundra_color = |_elev, moisture| ({
		r = tg_clamp8((140 + I64.div_trunc_by(moisture, 20)))
		g = tg_clamp8((155 + I64.div_trunc_by(moisture, 15)))
		b = tg_clamp8((130 + I64.div_trunc_by(moisture, 25)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_forest_color : I64, I64 -> I64
	tg_forest_color = |_elev, temp| ({
		r = tg_clamp8((20 + I64.div_trunc_by(temp, 30)))
		g = tg_clamp8((80 + I64.div_trunc_by(temp, 10)))
		b = tg_clamp8((15 + I64.div_trunc_by(temp, 40)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_desert_color : I64, I64 -> I64
	tg_desert_color = |_elev, moisture| ({
		r = tg_clamp8((200 + I64.div_trunc_by(moisture, 20)))
		g = tg_clamp8((175 + I64.div_trunc_by(moisture, 15)))
		b = tg_clamp8((110 + I64.div_trunc_by(moisture, 10)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_savanna_color : I64, I64 -> I64
	tg_savanna_color = |_elev, moisture| ({
		r = tg_clamp8((140 + I64.div_trunc_by(moisture, 15)))
		g = tg_clamp8((160 + I64.div_trunc_by(moisture, 10)))
		b = tg_clamp8((60 + I64.div_trunc_by(moisture, 20)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_grassland_color : I64, I64 -> I64
	tg_grassland_color = |_elev, moisture| ({
		r = tg_clamp8((80 + I64.div_trunc_by(moisture, 20)))
		g = tg_clamp8((140 + I64.div_trunc_by(moisture, 8)))
		b = tg_clamp8((40 + I64.div_trunc_by(moisture, 25)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_mars_pixel : I64, I64, I64 -> I64
	tg_mars_pixel = |lat, lon, seed| ({
		elev = tg_fbm((lon * 3), (lat * 3), (seed + 100))
		detail = tg_fbm((lon * 8), (lat * 8), (seed + 200))
		abs_lat = (if (lat < 0) { (0 - lat) } else { lat })
		(if (abs_lat > 78) { tg_mars_cap(elev, abs_lat) } else { (if (elev > 650) { tg_mars_highland(elev, detail) } else { (if (elev < 300) { tg_mars_lowland(elev, detail) } else { tg_mars_mid(elev, detail) }) }) })
	})

	tg_mars_cap : I64, I64 -> I64
	tg_mars_cap = |_elev, abs_lat| ({
		ice = ((abs_lat - 78) * 20)
		r = tg_clamp8((200 + ice))
		g = tg_clamp8((190 + ice))
		b = tg_clamp8((180 + ice))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_mars_highland : I64, I64 -> I64
	tg_mars_highland = |_elev, detail| ({
		r = tg_clamp8((180 + I64.div_trunc_by(detail, 15)))
		g = tg_clamp8((100 + I64.div_trunc_by(detail, 20)))
		b = tg_clamp8((60 + I64.div_trunc_by(detail, 30)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_mars_lowland : I64, I64 -> I64
	tg_mars_lowland = |_elev, detail| ({
		r = tg_clamp8((140 + I64.div_trunc_by(detail, 12)))
		g = tg_clamp8((80 + I64.div_trunc_by(detail, 18)))
		b = tg_clamp8((50 + I64.div_trunc_by(detail, 25)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_mars_mid : I64, I64 -> I64
	tg_mars_mid = |elev, detail| ({
		r = tg_clamp8(((160 + I64.div_trunc_by(detail, 12)) + I64.div_trunc_by(elev, 20)))
		g = tg_clamp8(((90 + I64.div_trunc_by(detail, 18)) + I64.div_trunc_by(elev, 30)))
		b = tg_clamp8(((55 + I64.div_trunc_by(detail, 25)) + I64.div_trunc_by(elev, 40)))
		(((r * 65536) + (g * 256)) + b)
	})

	tg_generate! : Machine.Machine, TerrainGen.PlanetKind, I64 => (Machine.Machine, I64)
	tg_generate! = |machine, kind, seed| ({
		(machine1, _written) = tg_write_rows!(machine, kind, seed, 0)
		tg_upload_tex!(machine1, tex_buf_addr, tex_w, tex_h, 0)
	})

	tg_write_rows! : Machine.Machine, TerrainGen.PlanetKind, I64, I64 => (Machine.Machine, I64)
	tg_write_rows! = |machine, kind, seed, row| (if (row >= tex_h) { (machine, 0) } else { ({
		lat = (90 - I64.div_trunc_by((row * 180), tex_h))
		(machine1, _written) = tg_write_cols!(machine, kind, seed, lat, row, 0)
		tg_write_rows!(machine1, kind, seed, (row + 1))
	}) })

	tg_write_cols! : Machine.Machine, TerrainGen.PlanetKind, I64, I64, I64, I64 => (Machine.Machine, I64)
	tg_write_cols! = |machine, kind, seed, lat, row, col| (if (col >= tex_w) { (machine, 0) } else { ({
		lon = (I64.div_trunc_by((col * 360), tex_w) - 180)
		color = tg_pixel(kind, lat, lon, seed)
		offset = (((row * tex_w) + col) * 3)
		r = I64.div_trunc_by(color, 65536)
		g = (I64.div_trunc_by(color, 256) - (r * 256))
		b = (color - (I64.div_trunc_by(color, 256) * 256))
		(machine1, _wr) = Machine.store!(machine, tex_buf_addr, offset, r, 1)
		(machine2, _wg) = Machine.store!(machine1, tex_buf_addr, (offset + 1), g, 1)
		(machine3, _wb) = Machine.store!(machine2, tex_buf_addr, (offset + 2), b, 1)
		tg_write_cols!(machine3, kind, seed, lat, row, (col + 1))
	}) })

	tg_pixel : TerrainGen.PlanetKind, I64, I64, I64 -> I64
	tg_pixel = |kind, lat, lon, seed| (match kind {
		PkEarth => tg_earth_pixel(lat, lon, seed)
		PkMars => tg_mars_pixel(lat, lon, seed)
		PkRandom => tg_random_pixel(lat, lon, seed)
	})

	tg_random_pixel : I64, I64, I64 -> I64
	tg_random_pixel = |lat, lon, seed| ({
		elev = tg_fbm((lon * 3), (lat * 3), seed)
		moisture = tg_fbm(((lon * 2) + 70000), ((lat * 2) + 30000), (seed + 17))
		abs_lat = (if (lat < 0) { (0 - lat) } else { lat })
		base_r = (I64.div_trunc_by((tg_hash(seed, 1) * 200), 1000) + 40)
		base_g = (I64.div_trunc_by((tg_hash(seed, 2) * 200), 1000) + 40)
		base_b = (I64.div_trunc_by((tg_hash(seed, 3) * 200), 1000) + 40)
		ocean_r = (I64.div_trunc_by((tg_hash(seed, 4) * 80), 1000) + 10)
		ocean_g = (I64.div_trunc_by((tg_hash(seed, 5) * 80), 1000) + 20)
		ocean_b = (I64.div_trunc_by((tg_hash(seed, 6) * 150), 1000) + 80)
		(if (abs_lat > 80) { ({
			v = (200 + I64.div_trunc_by(elev, 20))
			(((tg_clamp8(v) * 65536) + (tg_clamp8((v + 5)) * 256)) + tg_clamp8((v + 10)))
		}) } else { (if (elev < 400) { ({
			depth = (400 - elev)
			(((tg_clamp8((ocean_r + I64.div_trunc_by(depth, 20))) * 65536) + (tg_clamp8((ocean_g + I64.div_trunc_by(depth, 15))) * 256)) + tg_clamp8((ocean_b + I64.div_trunc_by(depth, 8))))
		}) } else { ({
			height = (elev - 400)
			r = tg_clamp8(((base_r + I64.div_trunc_by(height, 8)) + I64.div_trunc_by(moisture, 15)))
			g = tg_clamp8(((base_g + I64.div_trunc_by(height, 10)) + I64.div_trunc_by(moisture, 10)))
			b = tg_clamp8((base_b + I64.div_trunc_by(height, 15)))
			(((r * 65536) + (g * 256)) + b)
		}) }) })
	})

	tg_clamp8 : I64 -> I64
	tg_clamp8 = |x| (if (x < 0) { 0 } else { (if (x > 255) { 255 } else { x }) })

	eq_PlanetKind : TerrainGen.PlanetKind, TerrainGen.PlanetKind -> Bool
	eq_PlanetKind = |ex, ey| (match ex {
		PkEarth => (match ey {
			PkEarth => True
			_ => False
		})
		PkMars => (match ey {
			PkMars => True
			_ => False
		})
		PkRandom => (match ey {
			PkRandom => True
			_ => False
		})
	})
}
