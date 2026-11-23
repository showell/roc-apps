// refused: ReferenceError: Cannot access 'x' before initialization
let x = 1;
{
  console.log(x);
  let x = 2;
}
