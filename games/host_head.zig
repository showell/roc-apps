const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const Model = ?[*]u8;
