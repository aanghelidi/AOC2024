const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const print = std.debug.print;

const utils = @import("utils.zig");

const data = @embedFile("day025/input.txt");

const H: usize = 7;
const W: usize = 5;
const V = @Vector(W, usize);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var locks = std.ArrayList([W]usize).init(allocator);
    defer locks.deinit();

    var keys = std.ArrayList([W]usize).init(allocator);
    defer keys.deinit();

    var it_schematics = mem.splitSequence(u8, data, "\n\n");
    while (it_schematics.next()) |raw_schematic| {
        var it_row = mem.tokenizeScalar(u8, raw_schematic, '\n');
        const is_lock: bool = if (mem.eql(u8, it_row.peek().?, "#" ** W)) true else false;
        var schematic: [H][W]u8 = undefined;
        var row: usize = 0;
        while (it_row.next()) |row_schema| {
            for (row_schema, 0..) |c, col| schematic[row][col] = c;
            row += 1;
        }
        var heigths: [W]usize = undefined;
        for (0..W) |col_s| {
            var height: usize = 0;
            for (0..H) |row_s| {
                if (schematic[row_s][col_s] == '#') height += 1;
            }
            heigths[col_s] = height - 1;
        }
        if (is_lock) {
            try locks.append(heigths);
        } else {
            try keys.append(heigths);
        }
    }
    var ans: u32 = 0;
    for (locks.items) |lock| {
        for (keys.items) |key| {
            const lock_v: V = lock;
            const key_v: V = key;
            const is_overlap = @reduce(.Or, (lock_v + key_v) > @as(V, @splat(5)));
            if (!is_overlap) ans += 1;
        }
    }
    print("Part 1: {d}\n", .{ans});
}
