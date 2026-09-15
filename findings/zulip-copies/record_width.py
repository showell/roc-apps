"""Write RecordWidth<K>.roc: a loop carrying one record of K F64 fields.

    python3 record_width.py <K> > RecordWidth<K>.roc

Each step hands the record to `step`, which updates two of its fields and
reads one more, and the loop carries the result on. The steps come from the
command line. A time per step that grows with K is the record being copied.
"""
import sys

k = int(sys.argv[1])
fields = [f"f{i}" for i in range(k)]
last, mid = fields[-1], fields[k // 2]
print(f"# A loop carrying a record of {k} F64 fields (record_width.py {k}).")
print()
print("R : { " + ", ".join(f"{f} : F64" for f in fields) + " }")
print()
print("step : R, F64 -> R")
print(f"step = |r, x| {{ ..r, f0: r.f0 + x, {last}: r.{last} * 0.5 + r.{mid} }}")
print()
print("run : R, U64, U64 -> R")
print("run = |r, i, n| if i >= n { r } else { run(step(r, U64.to_f64(i)), i + 1, n) }")
print()
print("main! = |args| {")
print('\tn = I64.to_u64_wrap(I64.from_str(List.get(args, 0) ?? "1000000") ?? 1000000)')
print("\tr0 = { " + ", ".join(f"{f}: {i}.0" for i, f in enumerate(fields)) + " }")
print("\tr = run(r0, 0, n)")
print(f"\techo!(F64.to_str(r.f0 + r.{last}))")
print("\tOk({})")
print("}")
