//! Every physics test, on one root: `zig build physics-test` runs them
//! natively, and `zig build physics-wasm` compiled to wasm32 (wasi), so the
//! page's target answers as the native one does.
test {
    _ = @import("physics.zig");
    _ = @import("grid.zig");
    _ = @import("layout.zig");
    _ = @import("physics_wire.zig");
    _ = @import("physics_page.zig");
}
