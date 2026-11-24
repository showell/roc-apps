// refused: unsupported: `this` in a static method
class A {
  static make() {
    return this;
  }
}
