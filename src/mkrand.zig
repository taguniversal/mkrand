const std = @import("std");

pub const Seg = u128;

pub const Field = [256]Seg;

pub const seedUnit: Seg =
    @as(u128, 1) << 64;

pub fn rule30(row: Seg) Seg {
    const left = std.math.rotr(Seg, row, 1);
    const center = row;
    const right = std.math.rotl(Seg, row, 1);

    return left ^ (center | right);
}

fn isHexChar(c: u8) bool {
    return (c >= '0' and c <= '9') or
        (c >= 'a' and c <= 'f') or
        (c >= 'A' and c <= 'F');
}

fn isHexString(s: []const u8) bool {
    if (s.len == 0) return false;

    for (s) |c| {
        if (!isHexChar(c)) return false;
    }

    return true;
}

pub fn parseSeed(value: []const u8) !Seg {
    var s = value;

    // PSI format: [<:HEX:>]
    if (std.mem.startsWith(u8, s, "[<:") and std.mem.endsWith(u8, s, ":>]")) {
        s = s[3 .. s.len - 3];
        return try std.fmt.parseInt(Seg, s, 16);
    }

    // Optional hex prefix
    if (std.mem.startsWith(u8, s, "0x") or std.mem.startsWith(u8, s, "0X")) {
        s = s[2..];
        return try std.fmt.parseInt(Seg, s, 16);
    }

    // Bare hex seed
    if (s.len <= 32 and isHexString(s)) {
        return try std.fmt.parseInt(Seg, s, 16);
    }

    // Arbitrary string seed
    return seedFromString(s);
}

pub fn printSeg(writer: anytype, seg: Seg) !void {
    var bit: u7 = 127;

    while (true) {
        const mask: u128 = @as(u128, 1) << bit;

        if ((seg & mask) != 0)
            try writer.print("1", .{})
        else
            try writer.print(".", .{});

        if (bit == 0)
            break;

        bit -= 1;
    }

    try writer.print("\n", .{});
}

pub fn printField(writer: anytype, rows: Field, count: usize) !void {
    var i: usize = 0;

    while (i < count and i < rows.len) : (i += 1) {
        try writer.print("{d: >3}: ", .{i});
        try printSeg(writer, rows[i]);
    }
}

pub fn field(seed: Seg) Field {
    var rows: Field = undefined;

    rows[0] = seed;

    var i: usize = 1;
    while (i < rows.len) : (i += 1) {
        rows[i] = rule30(rows[i - 1]);
    }

    return rows;
}

pub fn getBit(seg: Seg, bit: u7) u1 {
    return @intCast((seg >> bit) & 1);
}

pub fn sha30(seed: Seg) Seg {
    const rows = field(seed);

    var out: Seg = 0;
    const center_bit: u7 = 63;

    const start_row: usize = 128;
    const end_row: usize = 256;

    var row_index: usize = start_row;
    while (row_index < end_row) : (row_index += 1) {
        const bit = getBit(rows[row_index], center_bit);
        out = (out << 1) | bit;
    }

    return out;
}

pub fn seedFromString(s: []const u8) Seg {
    var state: Seg = seedUnit;

    for (s) |byte| {
        state ^= @as(Seg, byte);
        state = next(state);
    }

    return state;
}

pub fn next(state: Seg) Seg {
    return state ^ sha30(state);
}

test "seedUnit is center bit" {
    try std.testing.expectEqual(@as(Seg, @as(u128, 1) << 64), seedUnit);
}

test "rule30 first evolution from seed_unit" {
    const nextrule30 = rule30(seedUnit);
    try std.testing.expectEqual(@as(Seg, 0x38000000000000000), nextrule30);
}

test "field first rows match direct rule30 evolution" {
    const rows = field(seedUnit);

    try std.testing.expectEqual(seedUnit, rows[0]);
    try std.testing.expectEqual(rule30(seedUnit), rows[1]);
    try std.testing.expectEqual(rule30(rows[1]), rows[2]);
    try std.testing.expectEqual(rule30(rows[2]), rows[3]);
}

test "sha30 is deterministic" {
    const a = sha30(seedUnit);
    const b = sha30(seedUnit);

    try std.testing.expectEqual(a, b);
}

test "sha30 produces nonzero output for seedUnit" {
    try std.testing.expect(sha30(seedUnit) != 0);
}

test "rule30 wraps at boundaries" {
    const edge: Seg = @as(Seg, 1); // low bit set
    const next_row = rule30(edge);

    try std.testing.expect(next_row != 0);
}

test "parseSeed accepts hex prefix" {
    try std.testing.expectEqual(@as(Seg, 0x1234), try parseSeed("0x1234"));
    try std.testing.expectEqual(@as(Seg, 0x1234), try parseSeed("0X1234"));
}

test "parseSeed accepts psi format" {
    try std.testing.expectEqual(@as(Seg, 0x1234), try parseSeed("[<:1234:>]"));
}

test "parseSeed accepts bare hex" {
    try std.testing.expectEqual(@as(Seg, 0x1234), try parseSeed("1234"));
}

test "parseSeed falls back to string seed" {
    const a = try parseSeed("fuzz");
    const b = seedFromString("fuzz");

    try std.testing.expectEqual(a, b);
}

test "seedFromString is deterministic" {
    try std.testing.expectEqual(seedFromString("fuzz"), seedFromString("fuzz"));
}

test "different string seeds produce different seeds" {
    try std.testing.expect(seedFromString("fuzz") != seedFromString("storm"));
}

test "next is deterministic" {
    const a = next(seedUnit);
    const b = next(seedUnit);

    try std.testing.expectEqual(a, b);
}

test "next advances from seedUnit" {
    try std.testing.expect(next(seedUnit) != seedUnit);
}

test "getBit reads expected bits" {
    const seg: Seg = 0b1010;

    try std.testing.expectEqual(@as(u1, 0), getBit(seg, 0));
    try std.testing.expectEqual(@as(u1, 1), getBit(seg, 1));
    try std.testing.expectEqual(@as(u1, 0), getBit(seg, 2));
    try std.testing.expectEqual(@as(u1, 1), getBit(seg, 3));
}

test "parseSeed rejects invalid prefixed hex" {
    try std.testing.expectError(error.InvalidCharacter, parseSeed("0xzz"));
}

test "parseSeed rejects invalid psi hex" {
    try std.testing.expectError(error.InvalidCharacter, parseSeed("[<:zz:>]"));
}
