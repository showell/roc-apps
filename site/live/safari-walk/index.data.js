(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/RadioMast.glb", 2815380, 2955432], ["/assets/meshes/RadioTower.glb", 2955432, 3079500], ["/assets/meshes/Zebra.glb", 3079500, 3739052], ["/assets/shaders/Grass.manifest.json", 3739052, 3832458], ["/assets/shaders/Grass.shaderpack", 3832458, 4283178], ["/assets/shaders/Ground.manifest.json", 4283178, 4327111], ["/assets/shaders/Ground.shaderpack", 4327111, 4551229], ["/assets/shaders/build.json", 4551229, 4553379], ["/assets/shaders/dependencies.json", 4553379, 4553641], ["/assets/sky/afternoon/nx.png", 4553641, 4576890], ["/assets/sky/afternoon/ny.png", 4576890, 4578383], ["/assets/sky/afternoon/nz.png", 4578383, 4607154], ["/assets/sky/afternoon/px.png", 4607154, 4630516], ["/assets/sky/afternoon/py.png", 4630516, 4659621], ["/assets/sky/afternoon/pz.png", 4659621, 4678332], ["/assets/sky/dusk/nx.png", 4678332, 4701184], ["/assets/sky/dusk/ny.png", 4701184, 4702675], ["/assets/sky/dusk/nz.png", 4702675, 4731442], ["/assets/sky/dusk/px.png", 4731442, 4753106], ["/assets/sky/dusk/py.png", 4753106, 4783273], ["/assets/sky/dusk/pz.png", 4783273, 4800838]];
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
