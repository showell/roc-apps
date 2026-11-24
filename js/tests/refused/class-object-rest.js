// refused: unsupported: printing or listing a class instance
class P {
  constructor() {
    this.x = 1;
  }
}
const { x, ...others } = new P();
