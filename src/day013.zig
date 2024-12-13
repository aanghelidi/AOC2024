const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day013/input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var it = mem.splitSequence(u8, data, "\n\n");

    // Part 1
    var ans: i64 = 0;
    while (it.next()) |raw_machine| {
        var it_lines = mem.tokenizeScalar(u8, raw_machine, '\n');
        var n: usize = 0;
        var a_i: [2]i64 = undefined;
        var b_i: [2]i64 = undefined;
        var c_i: [2]i64 = undefined;
        while (it_lines.next()) |line| {
            const nums = try utils.ints(i64, line, allocator);
            defer nums.deinit();
            switch (n) {
                0 => {
                    a_i[0] = nums.items[0];
                    b_i[0] = nums.items[1];
                },
                1 => {
                    a_i[1] = nums.items[0];
                    b_i[1] = nums.items[1];
                },
                2 => {
                    c_i[0] = nums.items[0];
                    c_i[1] = nums.items[1];
                },
                else => unreachable,
            }
            n += 1;
        }
        const d = (a_i[0] * b_i[1]) - (b_i[0] * a_i[1]);
        const dx = (c_i[0] * b_i[1]) - (c_i[1] * a_i[1]);
        const dy = (a_i[0] * c_i[1]) - (b_i[0] * c_i[0]);
        if (@rem(dx, d) != 0 or @rem(dy, d) != 0) continue;
        const x = @divExact(dx, d);
        const y = @divExact(dy, d);
        if (x > 100 or y > 100) continue;
        ans += 3 * x + y;
    }
    print("Part 1: {d}\n", .{ans});

    // Part 2
    var ans2: i64 = 0;
    var it2 = mem.splitSequence(u8, data, "\n\n");
    while (it2.next()) |raw_machine| {
        var it_lines = mem.tokenizeScalar(u8, raw_machine, '\n');
        var n: usize = 0;
        var a_i: [2]i64 = undefined;
        var b_i: [2]i64 = undefined;
        var c_i: [2]i64 = undefined;
        while (it_lines.next()) |line| {
            const nums = try utils.ints(i64, line, allocator);
            defer nums.deinit();
            switch (n) {
                0 => {
                    a_i[0] = nums.items[0];
                    b_i[0] = nums.items[1];
                },
                1 => {
                    a_i[1] = nums.items[0];
                    b_i[1] = nums.items[1];
                },
                2 => {
                    c_i[0] = nums.items[0] + 10000000000000;
                    c_i[1] = nums.items[1] + 10000000000000;
                },
                else => unreachable,
            }
            n += 1;
        }
        const d = (a_i[0] * b_i[1]) - (b_i[0] * a_i[1]);
        const dx = (c_i[0] * b_i[1]) - (c_i[1] * a_i[1]);
        const dy = (a_i[0] * c_i[1]) - (b_i[0] * c_i[0]);
        if (@rem(dx, d) != 0 or @rem(dy, d) != 0) continue;
        const x = @divExact(dx, d);
        const y = @divExact(dy, d);
        ans2 += 3 * x + y;
    }
    print("Part 2: {d}\n", .{ans2});
}
