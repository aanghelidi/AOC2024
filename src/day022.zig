const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;

const utils = @import("utils.zig");

const data = @embedFile("day022/input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = mem.tokenizeScalar(u8, data, '\n');
    const T = i128;
    var ans: T = 0;
    var bananas = std.StringArrayHashMap(T).init(allocator);
    defer bananas.deinit();
    while (it.next()) |num| {
        var n = try std.fmt.parseInt(T, num, 10);
        try computeSecret(T, &n, 2000, allocator, &bananas);
        ans += n;
    }
    print("Part 1: {d}\n", .{ans});
    print("Part 2: {d}\n", .{std.mem.max(T, bananas.values())});
}

fn computeSecret(comptime T: type, n: *T, n_gens: usize, allocator: Allocator, bananas: *std.StringArrayHashMap(T)) !void {
    var n_gen: usize = 0;
    var price: T = 0;
    var changes = try std.ArrayList(T).initCapacity(allocator, n_gens);
    defer changes.deinit();
    var prices = try std.ArrayList(T).initCapacity(allocator, n_gens);
    defer prices.deinit();
    while (n_gen < n_gens) : (n_gen += 1) {
        const new_price = @mod(n.*, 10);
        if (n_gen > 0) {
            prices.appendAssumeCapacity(new_price);
            const change = new_price - price;
            changes.appendAssumeCapacity(change);
        }
        // 1
        const res1 = n.* * (1 << 6);
        mix(T, res1, n);
        prune(T, n);
        // 2
        const res2 = @divTrunc(n.*, 1 << 5);
        mix(T, res2, n);
        prune(T, n);
        // 3
        const res3 = n.* * (1 << 11);
        mix(T, res3, n);
        prune(T, n);
        price = new_price;
    }
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();
    for (0..changes.items.len) |i| {
        if (i > 4) {
            const seq = changes.items[i + 1 - 4 .. i + 1];
            const price_seq = prices.items[i];
            const seq_k = try std.fmt.allocPrint(allocator, "{d}", .{seq});
            if (!seen.contains(seq_k)) {
                if (bananas.get(seq_k)) |value| {
                    try bananas.put(seq_k, value + price_seq);
                } else {
                    try bananas.put(seq_k, price_seq);
                }
                try seen.put(seq_k, {});
            }
        }
    }
}

fn mix(comptime T: type, res: T, secret_number: *T) void {
    secret_number.* ^= res;
}

fn prune(comptime T: type, secret_number: *T) void {
    secret_number.* = @mod(secret_number.*, 16777216);
}
