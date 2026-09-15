# Material -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Maybe
import Texture

Material :: [].{
	ShadingModel : [Unlit, FlatShaded, GouraudShaded, PhongShaded]
	EngineMaterial : { emat_albedo : Color.Rgb, emat_diffuse : I64, emat_specular : I64, emat_shininess : I64, emat_shading : Material.ShadingModel, emat_wireframe : Bool, emat_double_sided : Bool, emat_opacity : I64, emat_texture : Maybe.Maybe(Texture.EngineTexture) }

	emat_default : Material.EngineMaterial
	emat_default = { emat_albedo: Color.rgb(200, 200, 200), emat_diffuse: 700, emat_specular: 300, emat_shininess: 16, emat_shading: PhongShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_color : Color.Rgb -> Material.EngineMaterial
	emat_color = |c| { emat_albedo: c, emat_diffuse: 700, emat_specular: 300, emat_shininess: 16, emat_shading: PhongShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_flat : Color.Rgb -> Material.EngineMaterial
	emat_flat = |c| { emat_albedo: c, emat_diffuse: 800, emat_specular: 200, emat_shininess: 4, emat_shading: FlatShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_shiny : Color.Rgb, I64 -> Material.EngineMaterial
	emat_shiny = |c, shine| { emat_albedo: c, emat_diffuse: 400, emat_specular: 800, emat_shininess: shine, emat_shading: PhongShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_unlit : Color.Rgb -> Material.EngineMaterial
	emat_unlit = |c| { emat_albedo: c, emat_diffuse: 0, emat_specular: 0, emat_shininess: 1, emat_shading: Unlit, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_wire : Color.Rgb -> Material.EngineMaterial
	emat_wire = |c| { emat_albedo: c, emat_diffuse: 0, emat_specular: 0, emat_shininess: 1, emat_shading: Unlit, emat_wireframe: True, emat_double_sided: True, emat_opacity: 1000, emat_texture: None }

	emat_set_opacity : Material.EngineMaterial, I64 -> Material.EngineMaterial
	emat_set_opacity = |m, o| { ..m, emat_opacity: o }

	emat_set_wireframe : Material.EngineMaterial, Bool -> Material.EngineMaterial
	emat_set_wireframe = |m, w| { ..m, emat_wireframe: w }

	emat_set_double_sided : Material.EngineMaterial, Bool -> Material.EngineMaterial
	emat_set_double_sided = |m, d| { ..m, emat_double_sided: d }

	emat_set_shading : Material.EngineMaterial, Material.ShadingModel -> Material.EngineMaterial
	emat_set_shading = |m, s| { ..m, emat_shading: s }

	emat_set_texture : Material.EngineMaterial, Texture.EngineTexture -> Material.EngineMaterial
	emat_set_texture = |m, t| { ..m, emat_texture: Just(t) }

	emat_textured : Texture.EngineTexture -> Material.EngineMaterial
	emat_textured = |t| emat_set_texture(emat_color(Color.rgb(255, 255, 255)), t)

	emat_red : Material.EngineMaterial
	emat_red = emat_color(Color.rgb(220, 50, 50))

	emat_green : Material.EngineMaterial
	emat_green = emat_color(Color.rgb(50, 200, 80))

	emat_blue : Material.EngineMaterial
	emat_blue = emat_color(Color.rgb(60, 120, 220))

	emat_white : Material.EngineMaterial
	emat_white = emat_color(Color.rgb(240, 240, 240))

	emat_gold : Material.EngineMaterial
	emat_gold = emat_shiny(Color.rgb(255, 215, 0), 64)

	emat_chrome : Material.EngineMaterial
	emat_chrome = emat_shiny(Color.rgb(200, 200, 210), 128)

	emat_ground : Material.EngineMaterial
	emat_ground = emat_flat(Color.rgb(120, 100, 80))

	emat_sky : Material.EngineMaterial
	emat_sky = emat_unlit(Color.rgb(135, 206, 235))

	format_emat : Material.EngineMaterial -> Str
	format_emat = |m| ({
		shade_name = (match m.emat_shading {
			Unlit => "unlit"
			FlatShaded => "flat"
			GouraudShaded => "gouraud"
			PhongShaded => "phong"
		})
		Str.concat(Str.concat(Str.concat(Str.concat("Material(", Color.format_rgb(m.emat_albedo)), ", "), shade_name), ")")
	})

	eq_ShadingModel : Material.ShadingModel, Material.ShadingModel -> Bool
	eq_ShadingModel = |ex, ey| (match ex {
		Unlit => (match ey {
			Unlit => True
			_ => False
		})
		FlatShaded => (match ey {
			FlatShaded => True
			_ => False
		})
		GouraudShaded => (match ey {
			GouraudShaded => True
			_ => False
		})
		PhongShaded => (match ey {
			PhongShaded => True
			_ => False
		})
	})
}
