const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day019/input.txt");
const LinearFifo = std.fifo.LinearFifo;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = mem.splitSequence(u8, data, "\n\n");
    const patterns: []const u8 = it.next().?;
    const designs: []const u8 = it.next().?;

    var words = std.StringHashMap(void).init(allocator);
    defer words.deinit();
    var it_patterns = mem.tokenizeSequence(u8, patterns, ", ");
    while (it_patterns.next()) |pattern| try words.put(pattern, {});
    var it_designs = mem.tokenizeScalar(u8, designs, '\n');
    var ans: u64 = 0;
    var ans2: u64 = 0;
    while (it_designs.next()) |design| {
        //const is_possible = try isPossible(design, &words, allocator);
        //if (is_possible) ans += 1;
        const ways = try countWays(design, &words, allocator);
        if (ways > 0) ans += 1;
        ans2 += ways;
    }
    print("Part 1: {d}\n", .{ans});
    print("Part 2: {d}\n", .{ans2});
}

fn isPossible(design: []const u8, words: *std.StringHashMap(void), allocator: Allocator) !bool {
    const fifo = LinearFifo(usize, .Dynamic);
    var queue: fifo = fifo.init(allocator);
    defer queue.deinit();
    try queue.writeItem(0);
    var seen = std.AutoHashMap(usize, void).init(allocator);
    defer seen.deinit();
    while (queue.readItem()) |start| {
        if (start == design.len) return true;
        for (start + 1..design.len + 1) |end| {
            if (seen.contains(end)) continue;
            if (words.contains(design[start..end])) {
                try queue.writeItem(end);
                try seen.put(end, {});
            }
        }
    }
    return false;
}

pub fn countWays(design: []const u8, words: *std.StringHashMap(void), allocator: Allocator) !u64 {
    var dp = try std.ArrayList(u64).initCapacity(allocator, design.len + 1);
    defer dp.deinit();
    try dp.appendNTimes(0, design.len + 1);
    dp.items[0] = 1;
    for (dp.items, 0..) |_, start| {
        if (start == design.len) break;
        for (start + 1..design.len + 1) |end| {
            const substring = design[start..end];
            if (words.contains(substring)) dp.items[end] += dp.items[start];
        }
    }

    return dp.items[design.len];
}
