// Many instances, most short-lived, so the collector runs while methods'
// closures and their instances are live and dead.
class Vec {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
  add(o) {
    return new Vec(this.x + o.x, this.y + o.y);
  }
  dot(o) {
    return this.x * o.x + this.y * o.y;
  }
}

class Particle extends Vec {
  constructor(x, y, id) {
    super(x, y);
    this.id = id;
    this.trail = [];
  }
  step(v) {
    const next = this.add(v);
    this.trail.push(this.x);
    if (this.trail.length > 4) this.trail.shift();
    this.x = next.x;
    this.y = next.y;
    return this;
  }
}

let total = new Vec(0, 0);
for (let i = 0; i < 3000; i++) {
  total = total.add(new Vec(i % 7, i % 3));
}
console.log(total.x, total.y, total.dot(new Vec(1, 1)));

const swarm = [];
for (let i = 0; i < 60; i++) {
  swarm.push(new Particle(i, -i, i));
}
for (let round = 0; round < 20; round++) {
  const wind = new Vec(round % 5, 1);
  for (const p of swarm) p.step(wind);
  if (round % 5 === 0) swarm.splice(0, 5);
}
let checksum = 0;
for (const p of swarm) checksum += p.x + p.y * 2 + p.trail.length + p.id;
console.log(swarm.length, checksum, swarm.every((p) => p instanceof Vec && p instanceof Particle));
