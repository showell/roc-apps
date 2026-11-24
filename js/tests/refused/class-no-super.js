// refused: unsupported: a derived class's constructor that never calls `super(...)`
class A {}
class B extends A {
  constructor() {
    console.log('no super');
  }
}
new B();
