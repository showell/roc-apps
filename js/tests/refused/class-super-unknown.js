// refused: unsupported: `super.fly`, which no parent class has
class A {}
class B extends A {
  m() {
    return super.fly();
  }
}
