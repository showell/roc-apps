// refused: unsupported: `super.fly`, a method no class this one extends has
class A {}
class B extends A {
  m() {
    return super.fly();
  }
}
