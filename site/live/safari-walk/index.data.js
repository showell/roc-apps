(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/Zebra.glb", 2815380, 3474932], ["/assets/shaders/Grass.manifest.json", 3474932, 3568338], ["/assets/shaders/Grass.shaderpack", 3568338, 4019058], ["/assets/shaders/Ground.manifest.json", 4019058, 4062991], ["/assets/shaders/Ground.shaderpack", 4062991, 4287109], ["/assets/shaders/build.json", 4287109, 4289259], ["/assets/shaders/dependencies.json", 4289259, 4289521], ["/assets/sky/afternoon/nx.png", 4289521, 4312770], ["/assets/sky/afternoon/ny.png", 4312770, 4314263], ["/assets/sky/afternoon/nz.png", 4314263, 4343034], ["/assets/sky/afternoon/px.png", 4343034, 4366396], ["/assets/sky/afternoon/py.png", 4366396, 4395501], ["/assets/sky/afternoon/pz.png", 4395501, 4414212], ["/assets/sky/dusk/nx.png", 4414212, 4437064], ["/assets/sky/dusk/ny.png", 4437064, 4438555], ["/assets/sky/dusk/nz.png", 4438555, 4467322], ["/assets/sky/dusk/px.png", 4467322, 4488986], ["/assets/sky/dusk/py.png", 4488986, 4519153], ["/assets/sky/dusk/pz.png", 4519153, 4536718]];
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
