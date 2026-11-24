// Outside the subset
class Point {
  constructor(x, y) { this.x = x; this.y = y; }
  get norm() { return Math.sqrt(this.x * this.x + this.y * this.y); }
}
console.log(new Point(3, 4).norm);
