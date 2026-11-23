// refused: unsupported: setTimeout's arguments after the delay
setTimeout((word) => console.log(word), 10, "hello");
