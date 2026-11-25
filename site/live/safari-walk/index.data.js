(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "images"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/images/smoke.png", 0, 7557], ["/assets/meshes/Grass_Common_Short.glb", 7557, 50589], ["/assets/meshes/Grass_Common_Tall.glb", 50589, 103049], ["/assets/meshes/Grass_Wispy_Tall.glb", 103049, 176381], ["/assets/meshes/Pine_1.glb", 176381, 1095361], ["/assets/meshes/Pine_3.glb", 1095361, 2105365], ["/assets/meshes/Pine_5.glb", 2105365, 2822937], ["/assets/meshes/RadioMast.glb", 2822937, 3044921], ["/assets/meshes/RadioTower.glb", 3044921, 3241573], ["/assets/meshes/Zebra.glb", 3241573, 3901125], ["/assets/shaders/Antialias.manifest.json", 3901125, 3904787], ["/assets/shaders/Antialias.shaderpack", 3904787, 3942508], ["/assets/shaders/Grass.manifest.json", 3942508, 4036003], ["/assets/shaders/Grass.shaderpack", 4036003, 4489032], ["/assets/shaders/Ground.manifest.json", 4489032, 4533066], ["/assets/shaders/Ground.shaderpack", 4533066, 4766056], ["/assets/shaders/Lattice.manifest.json", 4766056, 4810017], ["/assets/shaders/Lattice.shaderpack", 4810017, 4998073], ["/assets/shaders/Water.manifest.json", 4998073, 5042477], ["/assets/shaders/Water.shaderpack", 5042477, 5282736], ["/assets/shaders/build.json", 5282736, 5286753], ["/assets/shaders/dependencies.json", 5286753, 5287211], ["/assets/sky/afternoon/nx.png", 5287211, 5310460], ["/assets/sky/afternoon/ny.png", 5310460, 5311953], ["/assets/sky/afternoon/nz.png", 5311953, 5340724], ["/assets/sky/afternoon/px.png", 5340724, 5364086], ["/assets/sky/afternoon/py.png", 5364086, 5393191], ["/assets/sky/afternoon/pz.png", 5393191, 5411902], ["/assets/sky/dusk/nx.png", 5411902, 5434754], ["/assets/sky/dusk/ny.png", 5434754, 5436245], ["/assets/sky/dusk/nz.png", 5436245, 5465012], ["/assets/sky/dusk/px.png", 5465012, 5486676], ["/assets/sky/dusk/py.png", 5486676, 5516843], ["/assets/sky/dusk/pz.png", 5516843, 5534408]];
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
