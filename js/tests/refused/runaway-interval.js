// refused: the program ran past its budget of 100000 timer callbacks
// An interval never cleared: node runs it forever; js-vm stops it.
let n = 0;
setInterval(() => {
  n++;
}, 5);
