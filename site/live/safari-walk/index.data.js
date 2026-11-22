(function () {
	var Module = window.Module;
	var dirs = [["/", "assets"], ["/assets", "meshes"], ["/assets", "shaders"], ["/assets", "sky"], ["/assets/sky", "afternoon"], ["/assets/sky", "dusk"]];
	var files = [["/assets/meshes/Grass_Common_Short.glb", 0, 43032], ["/assets/meshes/Grass_Common_Tall.glb", 43032, 95492], ["/assets/meshes/Grass_Wispy_Tall.glb", 95492, 168824], ["/assets/meshes/Pine_1.glb", 168824, 1087804], ["/assets/meshes/Pine_3.glb", 1087804, 2097808], ["/assets/meshes/Pine_5.glb", 2097808, 2815380], ["/assets/meshes/Zebra.glb", 2815380, 3474932], ["/assets/shaders/Grass.manifest.json", 3474932, 3568338], ["/assets/shaders/Grass.shaderpack", 3568338, 4018536], ["/assets/shaders/Ground.manifest.json", 4018536, 4062469], ["/assets/shaders/Ground.shaderpack", 4062469, 4286587], ["/assets/shaders/build.json", 4286587, 4288737], ["/assets/shaders/dependencies.json", 4288737, 4288999], ["/assets/sky/afternoon/nx.png", 4288999, 4310976], ["/assets/sky/afternoon/ny.png", 4310976, 4312469], ["/assets/sky/afternoon/nz.png", 4312469, 4338206], ["/assets/sky/afternoon/px.png", 4338206, 4359396], ["/assets/sky/afternoon/py.png", 4359396, 4389656], ["/assets/sky/afternoon/pz.png", 4389656, 4408427], ["/assets/sky/dusk/nx.png", 4408427, 4431931], ["/assets/sky/dusk/ny.png", 4431931, 4433422], ["/assets/sky/dusk/nz.png", 4433422, 4463881], ["/assets/sky/dusk/px.png", 4463881, 4487973], ["/assets/sky/dusk/py.png", 4487973, 4520220], ["/assets/sky/dusk/pz.png", 4520220, 4539164]];
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
