## This module is the host's one effect, as the platform hands it to Roc.
## Book.roc is its only caller: an app reads a file through `Book.read_file!`,
## which turns this answer into a `Try`.
##
## The path is relative to the book's folder, the one named on the command
## line, and the host never reads outside that folder. An absolute path, a
## `..` that climbs above the folder, a symbolic link that resolves outside
## it and a NUL byte are each `OutsideTheBook`, and nothing is read. The
## host's checks are in host/book_folder.zig.
##
## The tags cross as one byte, numbered alphabetically, which is Roc's layout
## of a tag union with no payloads; host/abi_test.zig holds the host's enum to
## `roc glue`'s.
Host := [].{

	## The file's bytes (`Found`, in `bytes`), or why not: nothing there
	## (`NotFound`), a folder or another thing that is no plain file
	## (`NotAFile`), a path that leaves the book (`OutsideTheBook`), or any
	## other failure, such as a file the user may not read or one past the
	## host's size cap (`ReadFailed`). The bytes are empty unless `Found`.
	read_file! : List(U8) => {
		bytes : List(U8),
		status : [Found, NotAFile, NotFound, OutsideTheBook, ReadFailed],
	}
}
