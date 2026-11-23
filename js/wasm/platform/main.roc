# The JavaScript subset's platform for the browser: a program's text in, its
# transcript out, one call a run.
#
# The host never builds a Roc list itself. It asks the Roc for a buffer of
# the source's length (`buffer_for_host`), writes the source into it, and
# hands it back to `run_for_host`, which consumes it; the transcript it
# answers is handed back to `drop_for_host` before the next run. So the host
# needs no knowledge of how Roc lays out a list's reference count, only its
# three words.
platform ""
	requires {
		drop_transcript : List(U8) -> {},
		run_program : List(U8) -> List(U8),
		source_buffer : U32 -> List(U8)
	}
	exposes []
	packages {}
	provides { "roc_buffer": buffer_for_host, "roc_drop": drop_for_host, "roc_run": run_for_host }
	targets: {
		wasm32: {
			inputs: [app],
			output: Archive,
		},
	}

buffer_for_host : U32 -> List(U8)
buffer_for_host = |n| source_buffer(n)

run_for_host : List(U8) -> List(U8)
run_for_host = |src| run_program(src)

drop_for_host : List(U8) -> {}
drop_for_host = |transcript| drop_transcript(transcript)
