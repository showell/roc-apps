// The build options roc's `builtins` and `host_alloc` modules read, for a host
// built outside roc's own build. Every field a `@import("build_options")` in
// those modules touches, with the value roc's own build gives it.
pub const debug: bool = false;
pub const enable_tracy: bool = false;
pub const enable_tracy_callstack: bool = false;
pub const enable_tracy_allocation: bool = false;
pub const tracy_callstack_depth: u32 = 10;
pub const trace_refcount: bool = false;
pub const debug_gpa_stack_trace_frames: usize = 0;
