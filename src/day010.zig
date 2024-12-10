const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day010/input.txt");
const ParseInt = std.fmt.parseInt;

const Position = utils.Position;
const Order = math.Order;

const LavaPosition = struct { position: Position(isize), height: u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var grid = try parse(data, allocator);
    defer grid.deinit();

    var starts = std.ArrayList(LavaPosition).init(allocator);
    defer starts.deinit();
    for (grid.items) |lavas| {
        for (lavas.items) |lava| {
            if (lava.height == 0) try starts.append(lava);
        }
    }

    const PQ = std.PriorityQueue(LavaPosition, void, lessThanHeight);
    var total: u32 = 0;
    for (starts.items) |start| {
        var queue = PQ.init(allocator, {});
        defer queue.deinit();
        try queue.add(start);
        var score: u32 = 0;
        var visited = std.AutoHashMap(LavaPosition, void).init(allocator);
        defer visited.deinit();
        while (queue.removeOrNull()) |pos| {
            if (visited.contains(pos)) {
                continue;
            }
            if (pos.height == 9) {
                try visited.put(pos, {});
                score += 1;
                continue;
            }
            try visited.put(pos, {});
            var neighbours = try pos.position.N4(allocator);
            defer neighbours.deinit();
            for (neighbours.items) |npos| {
                if (!inGrid(isize, std.ArrayList(LavaPosition), npos, &grid)) continue;
                const row_idx = @as(usize, (@intCast(npos.row)));
                const col_idx = @as(usize, (@intCast(npos.col)));
                const lava_pos = grid.items[row_idx].items[col_idx];
                if (@as(i8, @intCast(lava_pos.height)) - @as(i8, @intCast(pos.height)) == 1) try queue.add(lava_pos);
            }
        }
        total += score;
    }
    print("Part 1: {d}\n", .{total});

    var total2: u32 = 0;
    for (starts.items) |start| {
        var queue = PQ.init(allocator, {});
        defer queue.deinit();
        try queue.add(start);
        var score: u32 = 0;
        while (queue.removeOrNull()) |pos| {
            if (pos.height == 9) {
                score += 1;
                continue;
            }
            var neighbours = try pos.position.N4(allocator);
            defer neighbours.deinit();
            for (neighbours.items) |npos| {
                if (!inGrid(isize, std.ArrayList(LavaPosition), npos, &grid)) continue;
                const row_idx = @as(usize, (@intCast(npos.row)));
                const col_idx = @as(usize, (@intCast(npos.col)));
                const lava_pos = grid.items[row_idx].items[col_idx];
                if (@as(i8, @intCast(lava_pos.height)) - @as(i8, @intCast(pos.height)) == 1) try queue.add(lava_pos);
            }
        }
        total2 += score;
    }
    print("Part 2: {d}\n", .{total2});
}

fn lessThanHeight(context: void, a: LavaPosition, b: LavaPosition) Order {
    _ = context;
    return std.math.order(a.height, b.height);
}

fn parse(input: []const u8, allocator: Allocator) !std.ArrayList(std.ArrayList(LavaPosition)) {
    var grid = std.ArrayList(std.ArrayList(LavaPosition)).init(allocator);
    var it = mem.tokenizeScalar(u8, input, '\n');
    var row: usize = 0;
    while (it.next()) |line| {
        var col: usize = 0;
        var positions = std.ArrayList(LavaPosition).init(allocator);
        for (line) |e| {
            const pos = Position(isize).init(@as(isize, @intCast(row)), @as(isize, @intCast(col)));
            const height = try ParseInt(u8, &[_]u8{e}, 10);
            try positions.append(.{ .position = pos, .height = height });
            col += 1;
        }
        try grid.append(positions);
        row += 1;
    }
    return grid;
}

fn inGrid(comptime T: type, comptime GT: type, pos: Position(T), grid: *std.ArrayList(GT)) bool {
    return pos.row >= 0 and pos.row < grid.items.len and pos.col >= 0 and pos.col < grid.items[0].items.len;
}
