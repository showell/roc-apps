# The JavaScript subset as the page's wasm module, on the platform in
# ../wasm/platform: a program's text in, one byte that says how the run
# ended and the transcript out.
#
# The first byte is 0 when the program ran to its end, 1 when it stopped
# with a fault and 2 when the parser refused it; after a fault or a
# refusal, the transcript's last line is `js: <why>`, as js-run prints it.
app [drop_transcript, run_program, source_buffer] { pf: platform "../wasm/platform/main.roc" }

import Interp
import Parser

# The page runs a program on the browser's main thread, so a run is held to
# a step budget that keeps the page from freezing for long.
page_step_limit : U64
page_step_limit = 3000000

source_buffer : U32 -> List(U8)
source_buffer = |n| List.repeat(0, n.to_u64())

run_program : List(U8) -> List(U8)
run_program = |bytes| {
	src = Str.from_utf8_lossy(bytes)
	match Parser.program_of(src) {
		Ok(program) => {
			outcome = Interp.run(program, page_step_limit)
			match outcome.status {
				Running => List.concat([0], outcome.out.to_utf8())
				Faulted(why) => List.concat([1], "${outcome.out}js: ${why}\n".to_utf8())
			}
		}
		Err(f) => List.concat(
			[2],
			"js: ${f.why} (line ${f.line.to_str()}, column ${f.column.to_str()})\n".to_utf8(),
		)
	}
}

drop_transcript : List(U8) -> {}
drop_transcript = |_transcript| {}
