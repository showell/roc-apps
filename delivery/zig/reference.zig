//! The Zig solver the Roc replaced, as one module for the bench
//! (src/bench.zig) and for its unit tests (`zig build reference-test`).

pub const geography = @import("geography.zig");
pub const orders = @import("orders.zig");
pub const roadgraph = @import("roadgraph.zig");
pub const solver = @import("solver.zig");

test {
    _ = geography;
    _ = orders;
    _ = roadgraph;
    _ = solver;
}
