(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/RadioMast.glb", 2815380, 2955432], ["/assets/meshes/RadioTower.glb", 2955432, 3079500], ["/assets/meshes/Zebra.glb", 3079500, 3739052], ["/assets/shaders/Antialias.manifest.json", 3739052, 3742714], ["/assets/shaders/Antialias.shaderpack", 3742714, 3780435], ["/assets/shaders/Grass.manifest.json", 3780435, 3873930], ["/assets/shaders/Grass.shaderpack", 3873930, 4326959], ["/assets/shaders/Ground.manifest.json", 4326959, 4370892], ["/assets/shaders/Ground.shaderpack", 4370892, 4597539], ["/assets/shaders/build.json", 4597539, 4600087], ["/assets/shaders/dependencies.json", 4600087, 4600436], ["/assets/sky/afternoon/nx.png", 4600436, 4623685], ["/assets/sky/afternoon/ny.png", 4623685, 4625178], ["/assets/sky/afternoon/nz.png", 4625178, 4653949], ["/assets/sky/afternoon/px.png", 4653949, 4677311], ["/assets/sky/afternoon/py.png", 4677311, 4706416], ["/assets/sky/afternoon/pz.png", 4706416, 4725127], ["/assets/sky/dusk/nx.png", 4725127, 4747979], ["/assets/sky/dusk/ny.png", 4747979, 4749470], ["/assets/sky/dusk/nz.png", 4749470, 4778237], ["/assets/sky/dusk/px.png", 4778237, 4799901], ["/assets/sky/dusk/py.png", 4799901, 4830068], ["/assets/sky/dusk/pz.png", 4830068, 4847633]];
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
