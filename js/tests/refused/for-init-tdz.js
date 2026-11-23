// refused: ReferenceError: Cannot access 'i' before initialization
const i = 3;
for (let i = i + 1; i < 5; i++) console.log(i);
