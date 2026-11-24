// refused: unsupported: a derived class's constructor without `super(...)`
class A {}
class B extends A {
  constructor() {
    console.log('no super');
  }
}
new B();
