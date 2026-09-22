# LaunchConfig -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

LaunchConfig :: [].{
	LaunchConfig : { lc_grid_x : I64, lc_grid_y : I64, lc_grid_z : I64, lc_block_x : I64, lc_block_y : I64, lc_block_z : I64, lc_shared_bytes : I64 }

	launch_config_1d : I64, I64 -> LaunchConfig.LaunchConfig
	launch_config_1d = |grid, block| { lc_grid_x: grid, lc_grid_y: 1, lc_grid_z: 1, lc_block_x: block, lc_block_y: 1, lc_block_z: 1, lc_shared_bytes: 0 }

	launch_config_for_num_elems : I64 -> LaunchConfig.LaunchConfig
	launch_config_for_num_elems = |n| ({
		block_size = 256
		grid_size = I64.div_trunc_by(((n + block_size) - 1), block_size)
		launch_config_1d(grid_size, block_size)
	})
}
