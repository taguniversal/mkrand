const std = @import("std");

pub const Seg = u128;

pub const Field = [256]Seg;

pub const seed_unit: Seg =
    @as(u128, 1) << 64;

pub fn rule30(row: Seg) Seg {
    const left = std.math.rotr(Seg, row, 1);
    const center = row;
    const right = std.math.rotl(Seg, row, 1);

    return left ^ (center | right);
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

pub fn next(state: Seg) Seg {
    return state ^ sha30(state);
}

test "seed_unit is center bit" {
    try std.testing.expectEqual(@as(Seg, @as(u128, 1) << 64), seed_unit);
}

test "rule30 first evolution from seed_unit" {
    const nextrule30 = rule30(seed_unit);
    try std.testing.expectEqual(@as(Seg, 0x38000000000000000), nextrule30);
}

test "field first rows match direct rule30 evolution" {
    const rows = field(seed_unit);

    try std.testing.expectEqual(seed_unit, rows[0]);
    try std.testing.expectEqual(rule30(seed_unit), rows[1]);
    try std.testing.expectEqual(rule30(rows[1]), rows[2]);
    try std.testing.expectEqual(rule30(rows[2]), rows[3]);
}

test "sha30 is deterministic" {
    const a = sha30(seed_unit);
    const b = sha30(seed_unit);

    try std.testing.expectEqual(a, b);
}

test "sha30 produces nonzero output for seed_unit" {
    try std.testing.expect(sha30(seed_unit) != 0);
}

test "rule30 wraps at boundaries" {
    const edge: Seg = @as(Seg, 1); // low bit set
    const next_row = rule30(edge);

    try std.testing.expect(next_row != 0);
}