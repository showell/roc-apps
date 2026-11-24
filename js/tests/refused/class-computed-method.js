// refused: unsupported: computed method names
const k = 'm';
class A {
  [k]() {
    return 1;
  }
}
