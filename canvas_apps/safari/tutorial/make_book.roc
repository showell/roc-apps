## This program prints the Safari Ride book as HTML pages, from what
## book.shale hands it, and that script writes them to files. A comment line
## opens each page and names its file. Text from the manuscript can't forge one,
## because the renderer and the fence hook escape it. A diagram's drawing goes
## into its page unescaped, so the hook refuses one that holds a comment.
app [main!] { md: "../../../../roc-markdown/package/main.roc" }

import Book
import Manuscript

main! = |args| {
	for page in Book.pages(Manuscript.read(args), Book.dividers) {
		echo!("<!-- book page: ${page.file} -->\n${page.html}")
	}
	Ok({})
}
