// refused: unsupported: printing or listing a class instance
class P {
  constructor() {
    this.x = 1;
  }
}
console.log('before');
console.log(new P());
