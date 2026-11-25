(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "images"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/images/puff.png", 0, 5135], ["/assets/images/smoke.png", 5135, 12692], ["/assets/meshes/Grass_Common_Short.glb", 12692, 55724], ["/assets/meshes/Grass_Common_Tall.glb", 55724, 108184], ["/assets/meshes/Grass_Wispy_Tall.glb", 108184, 181516], ["/assets/meshes/Pine_1.glb", 181516, 1100496], ["/assets/meshes/Pine_3.glb", 1100496, 2110500], ["/assets/meshes/Pine_5.glb", 2110500, 2828072], ["/assets/meshes/RadioMast.glb", 2828072, 3050056], ["/assets/meshes/RadioTower.glb", 3050056, 3246708], ["/assets/meshes/Zebra.glb", 3246708, 3906260], ["/assets/shaders/Antialias.manifest.json", 3906260, 3909922], ["/assets/shaders/Antialias.shaderpack", 3909922, 3947643], ["/assets/shaders/Grass.manifest.json", 3947643, 4041138], ["/assets/shaders/Grass.shaderpack", 4041138, 4494167], ["/assets/shaders/Ground.manifest.json", 4494167, 4538201], ["/assets/shaders/Ground.shaderpack", 4538201, 4771191], ["/assets/shaders/Lattice.manifest.json", 4771191, 4815152], ["/assets/shaders/Lattice.shaderpack", 4815152, 5003208], ["/assets/shaders/Water.manifest.json", 5003208, 5047612], ["/assets/shaders/Water.shaderpack", 5047612, 5287871], ["/assets/shaders/build.json", 5287871, 5291888], ["/assets/shaders/dependencies.json", 5291888, 5292346], ["/assets/sky/afternoon/nx.png", 5292346, 5315595], ["/assets/sky/afternoon/ny.png", 5315595, 5317088], ["/assets/sky/afternoon/nz.png", 5317088, 5345859], ["/assets/sky/afternoon/px.png", 5345859, 5369221], ["/assets/sky/afternoon/py.png", 5369221, 5398326], ["/assets/sky/afternoon/pz.png", 5398326, 5417037], ["/assets/sky/dusk/nx.png", 5417037, 5439889], ["/assets/sky/dusk/ny.png", 5439889, 5441380], ["/assets/sky/dusk/nz.png", 5441380, 5470147], ["/assets/sky/dusk/px.png", 5470147, 5491811], ["/assets/sky/dusk/py.png", 5491811, 5521978], ["/assets/sky/dusk/pz.png", 5521978, 5539543]];
	var data = fetch("index.data").then(function (response) {
		if (!response.ok) {
			throw new Error(response.status + " " + response.url);
		}
		return response.arrayBuffer();
	});
	Module["preRun"] = Module["preRun"] || [];
	Module["preRun"].push(function () {
		Module["addRunDependency"]("index.data");
		data.then(function (buffer) {
			var bytes = new Uint8Array(buffer);
			dirs.forEach(function (dir) { Module["FS_createPath"](dir[0], dir[1], true, true); });
			files.forEach(function (file) { Module["FS_createDataFile"](file[0], null, bytes.subarray(file[1], file[2]), true, true, true); });
			Module["removeRunDependency"]("index.data");
		}, function (error) {
			console.error(error);
			window.dispatchEvent(new CustomEvent("rocco:stopped", { detail: { reason: "load", message: "The page could not load index.data." } }));
		});
	});
})();
