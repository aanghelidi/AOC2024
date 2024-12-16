const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day015/input.txt");
const Position = utils.Position;

const PositionType = enum { ROBOT, BOX, WALL, SPACE };
const Direction = enum { WEST, NORTH, EAST, SOUTH };
const MapPosition = struct { position: Position(isize), type: PositionType, value: u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = mem.splitSequence(u8, data, "\n\n");
    var part_id: usize = 0;
    var map = std.ArrayList(std.ArrayList(MapPosition)).init(allocator);
    defer map.deinit();
    var moves: []const u8 = undefined;
    var current_position: Position(isize) = undefined;
    while (it.next()) |part| {
        switch (part_id) {
            0 => {
                var it_map = mem.tokenizeScalar(u8, part, '\n');
                var row_idx: usize = 0;
                while (it_map.next()) |row| {
                    var map_row = std.ArrayList(MapPosition).init(allocator);
                    for (row, 0..) |e, col_idx| {
                        switch (e) {
                            '#' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.WALL, .value = e });
                            },
                            'O' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.BOX, .value = e });
                            },
                            '@' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                current_position = position;
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.ROBOT, .value = e });
                            },
                            '.' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.SPACE, .value = e });
                            },
                            else => unreachable,
                        }
                    }
                    try map.append(map_row);
                    row_idx += 1;
                }
            },
            1 => {
                const trimmed_moves = mem.trim(u8, part, &ascii.whitespace);
                moves = trimmed_moves;
            },
            else => unreachable,
        }
        part_id += 1;
    }
    for (moves) |move| {
        try moveRobot(&map, move, &current_position, allocator);
    }
    const ans = sumGPS(u32, &map);
    print("Part 1: {d}\n", .{ans});
}

fn sumGPS(comptime T: type, map: *std.ArrayList(std.ArrayList(MapPosition))) T {
    var result: T = 0;
    for (map.items) |map_items| {
        for (map_items.items) |map_position| {
            if (!(map_position.type == PositionType.BOX)) continue;
            result += 100 * @as(T, @intCast(map_position.position.row)) + @as(T, @intCast(map_position.position.col));
        }
    }
    return result;
}

fn displayMap(map: *std.ArrayList(std.ArrayList(MapPosition))) void {
    for (map.items) |map_items| {
        for (map_items.items) |map_position| {
            print("{s}", .{map_position.value});
        }
        print("\n", .{});
    }
}

fn moveRobot(map: *std.ArrayList(std.ArrayList(MapPosition)), move: u8, position: *Position(isize), allocator: Allocator) !void {
    switch (move) {
        '<' => try moveDirection(map, position, Direction.WEST, allocator),
        '^' => try moveDirection(map, position, Direction.NORTH, allocator),
        '>' => try moveDirection(map, position, Direction.EAST, allocator),
        'v' => try moveDirection(map, position, Direction.SOUTH, allocator),
        else => {
            // something wrong here...
            print("", .{});
        },
    }
}

fn moveDirection(map: *std.ArrayList(std.ArrayList(MapPosition)), position: *Position(isize), direction: Direction, allocator: Allocator) !void {
    var robot_map_pos = &map.items[@as(usize, @intCast(position.row))].items[@as(usize, @intCast(position.col))];
    const offset = switch (direction) {
        Direction.WEST => Position(isize).init(0, -1),
        Direction.NORTH => Position(isize).init(-1, 0),
        Direction.EAST => Position(isize).init(0, 1),
        Direction.SOUTH => Position(isize).init(1, 0),
    };
    var maybe_next = &map.items[@as(usize, @intCast(position.row + offset.row))].items[@as(usize, @intCast(position.col + offset.col))];
    switch (maybe_next.type) {
        PositionType.WALL => return,
        PositionType.SPACE => {
            maybe_next.type = robot_map_pos.type;
            maybe_next.value = robot_map_pos.value;
            robot_map_pos.type = PositionType.SPACE;
            robot_map_pos.value = '.';
            position.row += offset.row;
            position.col += offset.col;
            return;
        },
        PositionType.BOX => {
            var boxes = std.ArrayList(*MapPosition).init(allocator);
            defer boxes.deinit();
            try boxes.append(maybe_next);
            var next_next = &map.items[@as(usize, @intCast(maybe_next.position.row + offset.row))].items[@as(usize, @intCast(maybe_next.position.col + offset.col))];
            if (next_next.type == PositionType.WALL) return;
            while (next_next.type == PositionType.BOX) {
                try boxes.append(next_next);
                next_next = &map.items[@as(usize, @intCast(next_next.position.row + offset.row))].items[@as(usize, @intCast(next_next.position.col + offset.col))];
                if (next_next.type == PositionType.WALL) return;
            }
            loop_box: while (boxes.popOrNull()) |box| {
                var next_to_box = &map.items[@as(usize, @intCast(box.position.row + offset.row))].items[@as(usize, @intCast(box.position.col + offset.col))];
                var box_map = &map.items[@as(usize, @intCast(box.position.row))].items[@as(usize, @intCast(box.position.col))];
                switch (next_to_box.type) {
                    PositionType.ROBOT => unreachable,
                    PositionType.BOX => unreachable,
                    PositionType.WALL => break :loop_box,
                    PositionType.SPACE => {
                        next_to_box.type = PositionType.BOX;
                        next_to_box.value = 'O';
                        box_map.type = PositionType.SPACE;
                        box_map.value = '.';
                    },
                }
            }
            maybe_next.type = robot_map_pos.type;
            maybe_next.value = robot_map_pos.value;
            robot_map_pos.type = PositionType.SPACE;
            robot_map_pos.value = '.';
            position.row += offset.row;
            position.col += offset.col;
            return;
        },
        PositionType.ROBOT => unreachable,
    }
}
