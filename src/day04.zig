const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day04/input.txt");

pub fn main() !void {
    var itLines = mem.tokenizeScalar(u8, data, '\n');
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    while (itLines.next()) |line| {
        try lines.append(line);
    }

    const n = lines.items.len;
    const m = lines.items[0].len;
    var ans: u32 = 0;
    var ans2: u32 = 0;
    var row: usize = 0;
    while (row < n) : (row += 1) {
        var col: usize = 0;
        while (col < m) : (col += 1) {
            if (col + 3 < m and (std.mem.eql(u8, lines.items[row][col .. col + 4], "XMAS") or std.mem.eql(u8, lines.items[row][col .. col + 4], "SAMX"))) ans += 1;
            if (row + 3 < n and
                ((lines.items[row][col] == 'X' and lines.items[row + 1][col] == 'M' and lines.items[row + 2][col] == 'A' and lines.items[row + 3][col] == 'S') or
                (lines.items[row][col] == 'S' and lines.items[row + 1][col] == 'A' and lines.items[row + 2][col] == 'M' and lines.items[row + 3][col] == 'X')))
            {
                ans += 1;
            }
            if (row >= 3 and row - 3 >= 0 and col + 3 < m and
                ((lines.items[row][col] == 'X' and lines.items[row - 1][col + 1] == 'M' and lines.items[row - 2][col + 2] == 'A' and lines.items[row - 3][col + 3] == 'S') or
                (lines.items[row][col] == 'S' and lines.items[row - 1][col + 1] == 'A' and lines.items[row - 2][col + 2] == 'M' and lines.items[row - 3][col + 3] == 'X')))
            {
                ans += 1;
            }
            if (row + 3 < n and col + 3 < m and
                ((lines.items[row][col] == 'X' and lines.items[row + 1][col + 1] == 'M' and lines.items[row + 2][col + 2] == 'A' and lines.items[row + 3][col + 3] == 'S') or
                (lines.items[row][col] == 'S' and lines.items[row + 1][col + 1] == 'A' and lines.items[row + 2][col + 2] == 'M' and lines.items[row + 3][col + 3] == 'X')))
            {
                ans += 1;
            }

            if (row + 2 < n and col + 2 < m and
                ((lines.items[row][col] == 'M' and lines.items[row + 1][col + 1] == 'A' and lines.items[row + 2][col] == 'M' and lines.items[row][col + 2] == 'S' and lines.items[row + 2][col + 2] == 'S') or
                (lines.items[row][col] == 'S' and lines.items[row + 1][col + 1] == 'A' and lines.items[row + 2][col] == 'M' and lines.items[row][col + 2] == 'S' and lines.items[row + 2][col + 2] == 'M') or
                (lines.items[row][col] == 'M' and lines.items[row + 1][col + 1] == 'A' and lines.items[row + 2][col] == 'S' and lines.items[row][col + 2] == 'M' and lines.items[row + 2][col + 2] == 'S') or
                (lines.items[row][col] == 'S' and lines.items[row + 1][col + 1] == 'A' and lines.items[row + 2][col] == 'S' and lines.items[row][col + 2] == 'M' and lines.items[row + 2][col + 2] == 'M')))
            {
                ans2 += 1;
            }
        }
    }
    print("Part 1: {d}\n", .{ans});
    print("Part 2: {d}\n", .{ans2});
}
