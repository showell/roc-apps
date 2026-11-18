## This is the book platform. A book app is one effectful function, `main!`,
## which the host calls once with the book's folder as the command line named
## it. The app reads the manuscript through `Book.read_file!`, the platform's
## one effect, and answers the text to print: `Ok` goes to stdout and the
## program exits 0; `Err` goes to stderr and it exits 1.
##
## The host (host/) reads only under the book's folder and writes nothing but
## stdout and stderr. Each function here is annotated with concrete types,
## because a provided function whose type is still polymorphic passes
## `roc check` and crashes at run time.
platform ""
	requires {
		main! : Str => Try(Str, Str)
	}
	exposes [Book]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted { "read_file": Host.read_file! }
	targets: {
		x64musl: {
			inputs: [app],
			output: Archive,
		},
	}

import Book
import Host

## The app's answer laid flat for the host: `outcome` says which stream
## `text` goes to. The host checks that the folder's name is UTF-8 before it
## calls, so the crash is the host's broken promise.
main_for_host! : List(U8) => { outcome : [Failed, Printed], text : List(U8) }
main_for_host! = |folder_bytes| {
	folder =
		match Str.from_utf8(folder_bytes) {
			Ok(text) => text
			Err(_) => crash "main_for_host!: the host hands a folder name that is not UTF-8"
		}
	match main!(folder) {
		Ok(output) => { outcome: Printed, text: output.to_utf8() }
		Err(message) => { outcome: Failed, text: message.to_utf8() }
	}
}
