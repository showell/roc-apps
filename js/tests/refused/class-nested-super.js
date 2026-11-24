// refused: unsupported: `super(...)` anywhere but a statement of its own
class A {}
class B extends A {
  constructor(flag) {
    if (flag) {
      super();
    }
  }
}
