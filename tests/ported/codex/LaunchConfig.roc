# LaunchConfig -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

LaunchConfig :: [].{
	LaunchConfig := { lc_grid_x : I64, lc_grid_y : I64, lc_grid_z : I64, lc_block_x : I64, lc_block_y : I64, lc_block_z : I64, lc_shared_bytes : I64 }.{
		is_eq : LaunchConfig.LaunchConfig, LaunchConfig.LaunchConfig -> Bool
		is_eq = |a, b| eq_LaunchConfig(a, b)
	}

	launch_config_1d : I64, I64 -> LaunchConfig.LaunchConfig
	launch_config_1d = |grid, block| LaunchConfig.LaunchConfig.{ lc_grid_x: grid, lc_grid_y: 1, lc_grid_z: 1, lc_block_x: block, lc_block_y: 1, lc_block_z: 1, lc_shared_bytes: 0 }

	launch_config_for_num_elems : I64 -> LaunchConfig.LaunchConfig
	launch_config_for_num_elems = |n| ({
		block_size : I64
		block_size = 256
		grid_size : I64
		grid_size = I64.div_trunc_by(((n + block_size) - 1), block_size)
		launch_config_1d(grid_size, block_size)
	})

	eq_LaunchConfig : LaunchConfig.LaunchConfig, LaunchConfig.LaunchConfig -> Bool
	eq_LaunchConfig = |ex, ey| (((((((ex.lc_grid_x == ey.lc_grid_x) and (ex.lc_grid_y == ey.lc_grid_y)) and (ex.lc_grid_z == ey.lc_grid_z)) and (ex.lc_block_x == ey.lc_block_x)) and (ex.lc_block_y == ey.lc_block_y)) and (ex.lc_block_z == ey.lc_block_z)) and (ex.lc_shared_bytes == ey.lc_shared_bytes))
}
