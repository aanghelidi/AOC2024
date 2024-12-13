const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day011/input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const stones = try utils.positiveInts(u64, data, allocator);
    defer stones.deinit();
    var cache = std.AutoHashMap(struct { u64, usize }, u64).init(allocator);
    defer cache.deinit();
    var ans: u64 = 0;
    for (stones.items) |stone| {
        ans += try blink(stone, 25, &cache);
    }
    print("Part 1: {d}\n", .{ans});

    var ans2: u64 = 0;
    for (stones.items) |stone| {
        ans2 += try blink(stone, 75, &cache);
    }
    print("Part 2: {d}\n", .{ans2});
}

fn blink(stone: u64, n_step: usize, cache: *std.AutoHashMap(struct { u64, usize }, u64)) !u64 {
    if (cache.get(.{ stone, n_step })) |value| return value;
    var count: u64 = undefined;
    if (n_step == 0) {
        count = 1;
    } else if (stone == 0) {
        count = try blink(1, n_step - 1, cache);
    } else if (hasEvenNDigits(u64, stone)) {
        const num_parts = splitIn2(u64, stone);
        count = try blink(num_parts[0], n_step - 1, cache) + try blink(num_parts[1], n_step - 1, cache);
    } else {
        count = try blink(stone * 2024, n_step - 1, cache);
    }
    try cache.put(.{ stone, n_step }, count);
    return count;
}

fn hasEvenNDigits(comptime T: type, num: T) bool {
    var n = @abs(num);
    if (n == 0) return false;
    var digit_count: u64 = 0;
    while (n > 0) : (n /= 10) {
        digit_count += 1;
    }
    return @mod(digit_count, 2) == 0;
}

fn splitIn2(comptime T: type, num: T) [2]T {
    const n = @abs(num);
    if (n == 0) return [2]T{ 0, 0 };
    var digit_count: u64 = 0;
    var tmp = n;
    while (tmp > 0) : (tmp /= 10) {
        digit_count += 1;
    }
    const midpoint = @divExact(digit_count, 2);
    const divider = std.math.pow(T, 10, midpoint);

    const left = n / divider;
    const right = @mod(n, divider);
    return [2]T{ left, right };
}

test "digits count" {
    try testing.expect(hasEvenNDigits(u64, 0) == false);
    try testing.expect(hasEvenNDigits(u64, 1) == false);
    try testing.expect(hasEvenNDigits(u64, 12) == true);
    try testing.expect(hasEvenNDigits(u64, 20) == true);
    try testing.expect(hasEvenNDigits(i32, -12) == true);
    try testing.expect(hasEvenNDigits(i32, -123438) == true);
    try testing.expect(hasEvenNDigits(u64, 123438) == true);
}

test "split digits in 2" {
    try testing.expectEqualSlices(u64, &[2]u64{ 12, 34 }, &splitIn2(u64, 1234));
    try testing.expectEqualSlices(u64, &[2]u64{ 2, 0 }, &splitIn2(u64, 20));
    try testing.expectEqualSlices(u64, &[2]u64{ 0, 0 }, &splitIn2(u64, 0));
    try testing.expectEqualSlices(u64, &[2]u64{ 1703, 4242 }, &splitIn2(u64, 17034242));
}
