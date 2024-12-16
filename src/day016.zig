const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day016/input.txt");
const Position = utils.Position;
const Order = std.math.Order;

const Tile = struct { value: u8, position: Position(isize), dir: isize = 0 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = std.ArrayList(std.ArrayList(Tile)).init(allocator);
    defer map.deinit();
    var it = mem.tokenizeScalar(u8, data, '\n');
    var start_position: Position(isize) = undefined;
    var end_position: Position(isize) = undefined;
    var row_idx: isize = 0;
    while (it.next()) |row| {
        var row_list = std.ArrayList(Tile).init(allocator);
        var col_idx: isize = 0;
        for (row) |e| {
            try row_list.append(Tile{ .value = e, .position = Position(isize).init(row_idx, col_idx) });
            if (e == 'S') start_position = Position(isize).init(row_idx, col_idx);
            if (e == 'E') end_position = Position(isize).init(row_idx, col_idx);
            col_idx += 1;
        }
        try map.append(row_list);
        row_idx += 1;
    }

    const directions: [4]struct { isize, isize } = .{
        .{ 0, 1 }, // East
        .{ 1, 0 }, // South
        .{ 0, -1 }, // West
        .{ -1, 0 }, // North
    };
    const Path = std.ArrayList(Position(isize));
    const PQ = std.PriorityQueue(struct { Tile, u32, Path }, void, lessThanScore);
    var queue = PQ.init(allocator, {});
    const tile_start = getTile(&map, start_position.row, start_position.col);
    const tile_end = getTile(&map, end_position.row, end_position.col);
    var start_path = Path.init(allocator);
    try start_path.append(start_position);
    try queue.add(.{ tile_start, 0, start_path });
    var scores = std.AutoHashMap(Tile, u32).init(allocator);
    defer scores.deinit();
    try scores.put(tile_start, 0);
    var cost_path = std.AutoHashMap(u32, Path).init(allocator);
    defer cost_path.deinit();
    var next: Tile = undefined;
    var new_cost: u32 = undefined;

    while (queue.removeOrNull()) |tile_score_path| {
        const tile = tile_score_path[0];
        const path = tile_score_path[2];
        if (tile.position.row == end_position.row and tile.position.col == end_position.col) {
            //print("Part 1: {d}\n", .{scores.get(tile).?});
            //break;
            try cost_path.put(scores.get(tile).?, path);
            continue;
        }
        var forward_dir = directions[@as(usize, @intCast(tile.dir))];
        if (isInside(&map, tile.position.row + forward_dir[0], tile.position.col + forward_dir[1])) {
            next = getTile(&map, tile.position.row + forward_dir[0], tile.position.col + forward_dir[1]);
            next.dir = tile.dir;
            if (next.value != '#') {
                new_cost = scores.get(tile).? + 1;
                if (!scores.contains(next) or new_cost < scores.get(next).?) {
                    try scores.put(next, new_cost);
                    var new_path = Path.init(allocator);
                    for (path.items) |p| {
                        try new_path.append(p);
                    }
                    try new_path.append(next.position);
                    try queue.add(.{ next, new_cost + heuristic(tile_end, next), new_path });
                }
            }
        }

        const next_dir = @mod(tile.dir + 1, 4);
        forward_dir = directions[@as(usize, @intCast(next_dir))];
        if (isInside(&map, tile.position.row + forward_dir[0], tile.position.col + forward_dir[1])) {
            next = getTile(&map, tile.position.row + forward_dir[0], tile.position.col + forward_dir[1]);
            next.dir = next_dir;
            if (next.value != '#') {
                new_cost = scores.get(tile).? + 1000 + 1;
                if (!scores.contains(next) or new_cost < scores.get(next).?) {
                    try scores.put(next, new_cost);
                    var new_path = Path.init(allocator);
                    for (path.items) |p| {
                        try new_path.append(p);
                    }
                    try new_path.append(next.position);
                    try queue.add(.{ next, new_cost + heuristic(tile_end, next), new_path });
                }
            }
        }

        const next_dir_counter = @mod(tile.dir - 1, 4);
        forward_dir = directions[@as(usize, @intCast(next_dir_counter))];
        if (isInside(&map, tile.position.row + forward_dir[0], tile.position.col + forward_dir[1])) {
            next = getTile(&map, tile.position.row + forward_dir[0], tile.position.col + forward_dir[1]);
            next.dir = next_dir_counter;
            if (next.value != '#') {
                new_cost = scores.get(tile).? + 1000 + 1;
                if (!scores.contains(next) or new_cost < scores.get(next).?) {
                    try scores.put(next, new_cost);
                    var new_path = Path.init(allocator);
                    for (path.items) |p| {
                        try new_path.append(p);
                    }
                    try new_path.append(next.position);
                    try queue.add(.{ next, new_cost + heuristic(tile_end, next), new_path });
                }
            }
        }
    }

    var it_cost_path_key = cost_path.keyIterator();
    var ans: u32 = math.maxInt(u32);
    while (it_cost_path_key.next()) |k| {
        if (k.* < ans) ans = k.*;
    }
    print("Part 1: {d}\n", .{ans});

    var best_tiles = std.AutoHashMap(Position(isize), void).init(allocator);
    defer best_tiles.deinit();
    var it_cost_path_value = cost_path.valueIterator();
    while (it_cost_path_value.next()) |path| {
        for (path.items) |pos| {
            if (best_tiles.contains(pos)) continue;
            try best_tiles.put(pos, {});
        }
    }
    print("Part 2: {d}\n", .{best_tiles.count()});
}

fn heuristic(goal: Tile, next: Tile) u32 {
    return @as(u32, @intCast(@abs(goal.position.row - next.position.row) + @abs(goal.position.col - next.position.col)));
}

fn lessThanScore(context: void, a: struct { Tile, u32, std.ArrayList(Position(isize)) }, b: struct { Tile, u32, std.ArrayList(Position(isize)) }) Order {
    _ = context;
    return std.math.order(a[1], b[1]);
}

fn getTile(map: *std.ArrayList(std.ArrayList(Tile)), row: isize, col: isize) Tile {
    return map.items[@as(usize, @intCast(row))].items[@as(usize, @intCast(col))];
}

fn isInside(map: *std.ArrayList(std.ArrayList(Tile)), row: isize, col: isize) bool {
    const H = map.items.len;
    const W = map.items[0].items.len;
    return row >= 0 and row < H and col >= 0 and col < W;
}
