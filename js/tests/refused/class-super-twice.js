// refused: unsupported: `super(...)` called twice
class A {}
class B extends A {
  constructor() {
    super();
    super();
  }
}
