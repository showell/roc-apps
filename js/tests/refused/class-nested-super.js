// refused: unsupported: `super(...)` inside a block or an expression
class A {}
class B extends A {
  constructor(flag) {
    if (flag) {
      super();
    }
  }
}
