// refused: unsupported: `this` outside a class's constructor and methods
class A {
  m() {
    return function () {
      return this;
    };
  }
}
