## This module is what a book app reads its manuscript through. Its one
## effect, `read_file!`, reads a file under the book's folder and gives its
## text, or a tag that says why it could not.
Book := [].{

	## The text of the file at `path`, relative to the book's folder. Each
	## error tag is one reason: `OutsideTheBook` for a path that would leave
	## the folder (absolute, a `..` that climbs out, a symbolic link that
	## resolves outside, a NUL byte), `NotFound`, `NotAFile` for a folder,
	## `NotUtf8` for bytes that are not text, and `ReadFailed` for anything
	## else the host could not read.
	read_file! : Str => Try(Str, [NotAFile, NotFound, NotUtf8, OutsideTheBook, ReadFailed])
	read_file! = |path| text_of(Host.read_file!(path.to_utf8()))
}

import Host

## The host's answer as the app sees it. The bytes are decoded here, once, so
## text past this point is a `Str`.
text_of : {
	bytes : List(U8),
	status : [Found, NotAFile, NotFound, OutsideTheBook, ReadFailed],
} -> Try(Str, [NotAFile, NotFound, NotUtf8, OutsideTheBook, ReadFailed])
text_of = |answer| match answer.status {
	Found => Str.from_utf8(answer.bytes).map_err(|_| NotUtf8)
	NotAFile => Err(NotAFile)
	NotFound => Err(NotFound)
	OutsideTheBook => Err(OutsideTheBook)
	ReadFailed => Err(ReadFailed)
}

expect text_of({ bytes: "# Title\n".to_utf8(), status: Found }) == Ok("# Title\n")
expect text_of({ bytes: [], status: Found }) == Ok("")
expect text_of({ bytes: [0xFF, 0xFE], status: Found }) == Err(NotUtf8)
expect
	[
		(NotAFile, Err(NotAFile)),
		(NotFound, Err(NotFound)),
		(OutsideTheBook, Err(OutsideTheBook)),
		(ReadFailed, Err(ReadFailed)),
	].all(|(status, answer)| text_of({ bytes: [], status }) == answer)
