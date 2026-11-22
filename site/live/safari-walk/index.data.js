(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/RadioMast.glb", 2815380, 3037364], ["/assets/meshes/RadioTower.glb", 3037364, 3234016], ["/assets/meshes/Zebra.glb", 3234016, 3893568], ["/assets/shaders/Antialias.manifest.json", 3893568, 3897230], ["/assets/shaders/Antialias.shaderpack", 3897230, 3934951], ["/assets/shaders/Fur.manifest.json", 3934951, 3977240], ["/assets/shaders/Fur.shaderpack", 3977240, 4182394], ["/assets/shaders/Grass.manifest.json", 4182394, 4275889], ["/assets/shaders/Grass.shaderpack", 4275889, 4728918], ["/assets/shaders/Ground.manifest.json", 4728918, 4772952], ["/assets/shaders/Ground.shaderpack", 4772952, 5005942], ["/assets/shaders/Lattice.manifest.json", 5005942, 5049903], ["/assets/shaders/Lattice.shaderpack", 5049903, 5237959], ["/assets/shaders/Water.manifest.json", 5237959, 5282363], ["/assets/shaders/Water.shaderpack", 5282363, 5522622], ["/assets/shaders/build.json", 5522622, 5527366], ["/assets/shaders/dependencies.json", 5527366, 5527873], ["/assets/sky/afternoon/nx.png", 5527873, 5551122], ["/assets/sky/afternoon/ny.png", 5551122, 5552615], ["/assets/sky/afternoon/nz.png", 5552615, 5581386], ["/assets/sky/afternoon/px.png", 5581386, 5604748], ["/assets/sky/afternoon/py.png", 5604748, 5633853], ["/assets/sky/afternoon/pz.png", 5633853, 5652564], ["/assets/sky/dusk/nx.png", 5652564, 5675416], ["/assets/sky/dusk/ny.png", 5675416, 5676907], ["/assets/sky/dusk/nz.png", 5676907, 5705674], ["/assets/sky/dusk/px.png", 5705674, 5727338], ["/assets/sky/dusk/py.png", 5727338, 5757505], ["/assets/sky/dusk/pz.png", 5757505, 5775070]];
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
