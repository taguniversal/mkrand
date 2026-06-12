const std = @import("std");

pub const Seg = u128;

pub const Field = [128]Seg;

pub const seed_unit: Seg =
    @as(u128, 1) << 64;

pub fn rule30(row: Seg) Seg {
    const left = row << 1;
    const center = row;
    const right = row >> 1;

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

    while (i < 128) : (i += 1) {
        rows[i] = rule30(rows[i - 1]);
    }

    return rows;
}

test "seed_unit is center bit" {
    try std.testing.expectEqual(@as(Seg, @as(u128, 1) << 64), seed_unit);
}

test "rule30 first evolution from seed_unit" {
    const next = rule30(seed_unit);
    try std.testing.expectEqual(@as(Seg, 0x38000000000000000), next);
}

test "field first rows match direct rule30 evolution" {
    const rows = field(seed_unit);

    try std.testing.expectEqual(seed_unit, rows[0]);
    try std.testing.expectEqual(rule30(seed_unit), rows[1]);
    try std.testing.expectEqual(rule30(rows[1]), rows[2]);
    try std.testing.expectEqual(rule30(rows[2]), rows[3]);
}