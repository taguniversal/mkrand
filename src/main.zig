const std = @import("std");
const Io = std.Io;


const mkrand = @import("mkrand.zig");

const Options = struct {
    blocks: usize = 1,
    format: Format = .hex,
    seed: ?mkrand.Seg = null,
};

const Format = enum {
    hex,
    bin,
    psi,
};

fn parseFormat(value: []const u8) !Format {
    if (std.mem.eql(u8, value, "hex")) return .hex;
    if (std.mem.eql(u8, value, "bin")) return .bin;
    if (std.mem.eql(u8, value, "psi")) return .psi;

    return error.InvalidFormat;
}

fn defaultSeed() mkrand.Seg {
    return mkrand.seed_unit;
}

fn parseSeed(value: []const u8) !mkrand.Seg {
    var s = value;

    // PSI format: [<:HEX:>]
    if (std.mem.startsWith(u8, s, "[<:") and std.mem.endsWith(u8, s, ":>]")) {
        s = s[3 .. s.len - 3];
    }

    // Optional hex prefix
    if (std.mem.startsWith(u8, s, "0x") or std.mem.startsWith(u8, s, "0X")) {
        s = s[2..];
    }

    return try std.fmt.parseInt(mkrand.Seg, s, 16);
}

fn parseArgs(args: []const []const u8) !Options {
    var opts = Options{};

    var i: usize = 1; // skip program name

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            return error.HelpRequested;
        } else if (std.mem.eql(u8, arg, "--blocks") or std.mem.eql(u8, arg, "-n")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.blocks = try std.fmt.parseInt(usize, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--format") or std.mem.eql(u8, arg, "-f")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.format = try parseFormat(args[i]);
        } else if (std.mem.eql(u8, arg, "--seed") or std.mem.eql(u8, arg, "-s")) {
            i += 1;
            if (i >= args.len) return error.MissingArgument;
            opts.seed = try parseSeed(args[i]);
        } else {
            return error.UnknownArgument;
        }
    }

    return opts;
}

fn printUsage(writer: anytype) !void {
    try writer.print(
        \\MKRAND - A Digital Random Bit Generator
        \\
        \\Usage:
        \\  mkrand [options]
        \\
        \\Options:
        \\  -n, --blocks <count>   Number of 128-bit blocks to generate
        \\  -f, --format <format>  Output format: hex | bin
        \\  -s, --seed <hex>       Initial 128-bit seed in hex
        \\  -h, --help             Show this help message
        \\
        \\Examples:
        \\  mkrand --blocks 5 --format hex
        \\  mkrand -n 5 -f bin
        \\  mkrand -n 10 -s 0x10000000000000000
        \\
    , .{});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    const opts = parseArgs(args) catch |err| switch (err) {
        error.HelpRequested => {
            try printUsage(stdout_writer);
            try stdout_writer.flush();
            return;
        },
        else => return err,
    };

    var state = opts.seed orelse defaultSeed();

    std.debug.print("seed: 0x{x:0>32}\n", .{state});

    var block: usize = 0;

    while (block < opts.blocks) : (block += 1) {
        state = mkrand.next(state);

        switch (opts.format) {
            .hex => try stdout_writer.print("0x{x:0>32}\n", .{state}),
            .bin => try mkrand.printSeg(stdout_writer, state),
            .psi => try stdout_writer.print("[<:{x:0>32}:>]\n", .{state}),
        }
    }

    try stdout_writer.flush();
}
