// refused: SyntaxError: Illegal continue statement: 'block' does not denote an iteration statement
for (;;) {
  block: {
    continue block;
  }
}
