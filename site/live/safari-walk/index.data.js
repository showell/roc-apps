(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/RadioMast.glb", 2815380, 3037364], ["/assets/meshes/RadioTower.glb", 3037364, 3234016], ["/assets/meshes/Zebra.glb", 3234016, 3893568], ["/assets/shaders/Antialias.manifest.json", 3893568, 3897230], ["/assets/shaders/Antialias.shaderpack", 3897230, 3934951], ["/assets/shaders/Grass.manifest.json", 3934951, 4028446], ["/assets/shaders/Grass.shaderpack", 4028446, 4481475], ["/assets/shaders/Ground.manifest.json", 4481475, 4525509], ["/assets/shaders/Ground.shaderpack", 4525509, 4758499], ["/assets/shaders/Lattice.manifest.json", 4758499, 4802460], ["/assets/shaders/Lattice.shaderpack", 4802460, 4990516], ["/assets/shaders/Water.manifest.json", 4990516, 5034920], ["/assets/shaders/Water.shaderpack", 5034920, 5275179], ["/assets/shaders/build.json", 5275179, 5279196], ["/assets/shaders/dependencies.json", 5279196, 5279654], ["/assets/sky/afternoon/nx.png", 5279654, 5302903], ["/assets/sky/afternoon/ny.png", 5302903, 5304396], ["/assets/sky/afternoon/nz.png", 5304396, 5333167], ["/assets/sky/afternoon/px.png", 5333167, 5356529], ["/assets/sky/afternoon/py.png", 5356529, 5385634], ["/assets/sky/afternoon/pz.png", 5385634, 5404345], ["/assets/sky/dusk/nx.png", 5404345, 5427197], ["/assets/sky/dusk/ny.png", 5427197, 5428688], ["/assets/sky/dusk/nz.png", 5428688, 5457455], ["/assets/sky/dusk/px.png", 5457455, 5479119], ["/assets/sky/dusk/py.png", 5479119, 5509286], ["/assets/sky/dusk/pz.png", 5509286, 5526851]];
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
