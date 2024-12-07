const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const print = std.debug.print;
const utils = @import("utils.zig");
const data = @embedFile("day06/input.txt");

const Position = utils.Position;

const dirs: [4]Position(isize) = .{
    .{ .row = -1, .col = 0 },
    .{ .row = 0, .col = 1 },
    .{ .row = 1, .col = 0 },
    .{ .row = 0, .col = -1 },
};

const PositionDir = struct { pos: Position(usize), dir: u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const grid = parse(data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer grid.deinit();

    const n = grid.items.len;
    const m = grid.items[0].len;

    var current = Position(usize).init(0, 0);
    var direction: u8 = 0;
    var row: usize = 0;

    while (row < n) : (row += 1) {
        var col: usize = 0;
        while (col < m) : (col += 1) {
            if (grid.items[row][col] == '^') {
                current.row = row;
                current.col = col;
                grid.items[row][col] = '.';
            }
        }
    }
    const start = current;
    var visited = std.AutoHashMap(Position(usize), void).init(allocator);
    defer visited.deinit();

    while (true) {
        if (!visited.contains(current)) try visited.put(current, {});
        const next_row_isize = @as(isize, @intCast(current.row)) + dirs[direction].row;
        const next_col_isize = @as(isize, @intCast(current.col)) + dirs[direction].col;
        if (!(0 <= next_col_isize and next_col_isize < @as(isize, @intCast(m)) and 0 <= next_row_isize and @as(isize, @intCast(next_row_isize)) < n)) {
            break;
        }
        const next_row = @as(usize, @intCast(next_row_isize));
        const next_col = @as(usize, @intCast(next_col_isize));

        if (grid.items[next_row][next_col] == '.') {
            current.row = next_row;
            current.col = next_col;
        } else {
            direction = @mod(direction + 1, 4);
        }
    }
    const ans = visited.count();
    print("Part 1: {}\n", .{ans});

    var visited_positions = visited.keyIterator();
    var ans2: u32 = 0;
    while (visited_positions.next()) |vp| {
        current.row = start.row;
        current.col = start.col;
        direction = 0;
        var visited_dir = std.AutoHashMap(PositionDir, void).init(allocator);
        defer visited_dir.deinit();
        while (true) {
            const pos_dir = PositionDir{ .pos = current, .dir = direction };
            if (visited_dir.contains(pos_dir)) {
                ans2 += 1;
                break;
            }
            try visited_dir.put(pos_dir, {});
            const next_row_isize = @as(isize, @intCast(current.row)) + dirs[direction].row;
            const next_col_isize = @as(isize, @intCast(current.col)) + dirs[direction].col;
            if (!(0 <= next_col_isize and next_col_isize < @as(isize, @intCast(m)) and 0 <= next_row_isize and @as(isize, @intCast(next_row_isize)) < n)) {
                break;
            }
            const next_row = @as(usize, @intCast(next_row_isize));
            const next_col = @as(usize, @intCast(next_col_isize));
            if (grid.items[next_row][next_col] == '#' or (vp.row == next_row and vp.col == next_col)) {
                direction = @mod(direction + 1, 4);
            } else {
                current.row = next_row;
                current.col = next_col;
            }
        }
    }
    print("Part 2: {}\n", .{ans2});
}

fn parse(input: []const u8, allocator: Allocator) !std.ArrayList([]u8) {
    var grid = std.ArrayList([]u8).init(allocator);
    var it = mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |row| {
        const mutable_row = try allocator.alloc(u8, row.len);
        @memcpy(mutable_row, row);
        try grid.append(mutable_row);
    }
    return grid;
}
