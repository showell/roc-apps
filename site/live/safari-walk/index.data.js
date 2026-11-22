(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/RadioMast.glb", 2815380, 2955432], ["/assets/meshes/RadioTower.glb", 2955432, 3079500], ["/assets/meshes/Zebra.glb", 3079500, 3739052], ["/assets/shaders/Grass.manifest.json", 3739052, 3832547], ["/assets/shaders/Grass.shaderpack", 3832547, 4285576], ["/assets/shaders/Ground.manifest.json", 4285576, 4329509], ["/assets/shaders/Ground.shaderpack", 4329509, 4553627], ["/assets/shaders/build.json", 4553627, 4555777], ["/assets/shaders/dependencies.json", 4555777, 4556039], ["/assets/sky/afternoon/nx.png", 4556039, 4579288], ["/assets/sky/afternoon/ny.png", 4579288, 4580781], ["/assets/sky/afternoon/nz.png", 4580781, 4609552], ["/assets/sky/afternoon/px.png", 4609552, 4632914], ["/assets/sky/afternoon/py.png", 4632914, 4662019], ["/assets/sky/afternoon/pz.png", 4662019, 4680730], ["/assets/sky/dusk/nx.png", 4680730, 4703582], ["/assets/sky/dusk/ny.png", 4703582, 4705073], ["/assets/sky/dusk/nz.png", 4705073, 4733840], ["/assets/sky/dusk/px.png", 4733840, 4755504], ["/assets/sky/dusk/py.png", 4755504, 4785671], ["/assets/sky/dusk/pz.png", 4785671, 4803236]];
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
