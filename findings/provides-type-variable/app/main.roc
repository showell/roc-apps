app [Model, program] { pf: platform "../platform/main.roc" }

Model : { seconds : F32 }

program = {
	init: |{}| Box.box({ seconds: 0.0 }),
}
