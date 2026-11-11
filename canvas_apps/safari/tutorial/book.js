// The Safari Ride book's one script for every page. A table may run as wide as
// the page allows, and a column of sentences then makes lines too long to
// read, so this marks each column that holds prose and book.css wraps it at a
// reading width. A column holds prose when its cells average more than
// PROSE_LENGTH characters, as an Explanation column does and a column of names
// does not.
const PROSE_LENGTH = 60;

for (const table of document.querySelectorAll("article table")) {
  const rows = [...table.rows];
  const columns = Math.max(...rows.map((row) => row.cells.length));
  for (let column = 0; column < columns; column++) {
    const cells = rows.map((row) => row.cells[column]).filter((cell) => cell);
    const body = cells.filter((cell) => cell.tagName === "TD");
    if (body.length === 0) continue;
    const average = body.reduce((sum, cell) => sum + cell.textContent.trim().length, 0) / body.length;
    if (average > PROSE_LENGTH) {
      for (const cell of cells) cell.classList.add("prose");
    }
  }
}
