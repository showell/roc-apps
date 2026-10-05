# Material -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Maybe
import Texture

Material :: [].{
	ShadingModel : [Unlit, FlatShaded, GouraudShaded, PhongShaded]
	EngineMaterial := { emat_albedo : Color.Rgb, emat_diffuse : I64, emat_specular : I64, emat_shininess : I64, emat_shading : Material.ShadingModel, emat_wireframe : Bool, emat_double_sided : Bool, emat_opacity : I64, emat_texture : Maybe.Maybe(Texture.EngineTexture) }.{
		is_eq : Material.EngineMaterial, Material.EngineMaterial -> Bool
		is_eq = |a, b| eq_EngineMaterial(a, b)
	}

	emat_color : Color.Rgb -> Material.EngineMaterial
	emat_color = |c| Material.EngineMaterial.{ emat_albedo: c, emat_diffuse: 700, emat_specular: 300, emat_shininess: 16, emat_shading: PhongShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_flat : Color.Rgb -> Material.EngineMaterial
	emat_flat = |c| Material.EngineMaterial.{ emat_albedo: c, emat_diffuse: 800, emat_specular: 200, emat_shininess: 4, emat_shading: FlatShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_shiny : Color.Rgb, I64 -> Material.EngineMaterial
	emat_shiny = |c, shine| Material.EngineMaterial.{ emat_albedo: c, emat_diffuse: 400, emat_specular: 800, emat_shininess: shine, emat_shading: PhongShaded, emat_wireframe: False, emat_double_sided: False, emat_opacity: 1000, emat_texture: None }

	emat_red : Material.EngineMaterial
	emat_red = emat_color(Color.rgb(220, 50, 50))

	emat_gold : Material.EngineMaterial
	emat_gold = emat_shiny(Color.rgb(255, 215, 0), 64)

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

	eq_EngineMaterial : Material.EngineMaterial, Material.EngineMaterial -> Bool
	eq_EngineMaterial = |ex, ey| ((((((((Color.eq_Rgb(ex.emat_albedo, ey.emat_albedo) and (ex.emat_diffuse == ey.emat_diffuse)) and (ex.emat_specular == ey.emat_specular)) and (ex.emat_shininess == ey.emat_shininess)) and eq_ShadingModel(ex.emat_shading, ey.emat_shading)) and (ex.emat_wireframe == ey.emat_wireframe)) and (ex.emat_double_sided == ey.emat_double_sided)) and (ex.emat_opacity == ey.emat_opacity)) and Maybe.eq_Maybe(ex.emat_texture, ey.emat_texture))
}
