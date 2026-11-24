// refused: unsupported: `for ... in`
class P {}
for (const k in new P()) {
  console.log(k);
}
