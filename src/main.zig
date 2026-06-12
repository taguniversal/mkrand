const std = @import("std");
const Io = std.Io;

const mkrand = @import("mkrand.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const seed = mkrand.seed_unit;
    const next = mkrand.rule30(seed);
    const f = mkrand.field(seed);

    try stdout_writer.print("MKRAND Zig Bootstrap\n", .{});
    try stdout_writer.print("Seed:\n", .{});
    try mkrand.printSeg(stdout_writer, seed);

    try stdout_writer.print("\nStep 1:\n", .{});
    try mkrand.printSeg(stdout_writer, next);

    try stdout_writer.print("\nField:\n", .{});
    try mkrand.printField(stdout_writer, f, 128);

    try stdout_writer.flush();
}