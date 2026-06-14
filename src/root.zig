//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const mkrand = @import("mkrand.zig");

const Io = std.Io;

pub const Seg = mkrand.Seg;
pub const printSeg = mkrand.printSeg;
pub const seedUnit = mkrand.seedUnit;
pub const next = mkrand.next;
/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
