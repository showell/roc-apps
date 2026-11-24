// refused: unsupported: `this` before `super(...)`
class A {}
class B extends A {
  constructor() {
    this.x = 1;
    super();
  }
}
