const std = @import("std");
const Io = std.Io;

const mkrand = @import("mkrand.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const seed = mkrand.seed_unit;
    const first_rule30_row = mkrand.rule30(seed);
    var state = seed;
    const f = mkrand.field(seed);

    try stdout_writer.print("MKRAND Zig Bootstrap\n", .{});
    try stdout_writer.print("Seed:\n", .{});
    try mkrand.printSeg(stdout_writer, seed);

    try stdout_writer.print("\nFirst Rule 30 row:\n", .{});
    try mkrand.printSeg(stdout_writer, first_rule30_row);

    try stdout_writer.print("\nField:\n", .{});
    try mkrand.printField(stdout_writer, f, 128);
    try stdout_writer.print("Seed:\n", .{});
    try mkrand.printSeg(stdout_writer, seed);

    try stdout_writer.print("\nNext (SHA30):\n", .{});
    const sha30 = mkrand.sha30(seed);
    try mkrand.printSeg(stdout_writer, sha30);

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const transformed = mkrand.sha30(state);
        const next_state = mkrand.next(state);

        try stdout_writer.print("\nStep {d}\n", .{i});
        try stdout_writer.print("state: 0x{x:0>32}\n", .{state});
        try stdout_writer.print("sha30: 0x{x:0>32}\n", .{transformed});
        try stdout_writer.print("next : 0x{x:0>32}\n", .{next_state});
        try stdout_writer.print("ones : {d}\n", .{@popCount(state)});
        try mkrand.printSeg(stdout_writer, state);

        state = next_state;
    }

    try stdout_writer.flush();
}
