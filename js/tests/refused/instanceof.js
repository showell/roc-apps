// refused: unsupported: `instanceof` of anything but a class's name
try {
} catch (e) {
  console.log(e instanceof Error);
}
