const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day015/sample3.txt");
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
                    var col_idx: usize = 0;
                    for (row) |e| {
                        switch (e) {
                            '#' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                const next_position = Position(isize).init(position.row, position.col + 1);
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.WALL, .value = e });
                                try map_row.append(MapPosition{ .position = next_position, .type = PositionType.WALL, .value = e });
                                col_idx += 1;
                            },
                            'O' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                const next_position = Position(isize).init(position.row, position.col + 1);
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.BOX, .value = '[' });
                                try map_row.append(MapPosition{ .position = next_position, .type = PositionType.BOX, .value = ']' });
                                col_idx += 1;
                            },
                            '@' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                const next_position = Position(isize).init(position.row, position.col + 1);
                                current_position = position;
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.ROBOT, .value = e });
                                try map_row.append(MapPosition{ .position = next_position, .type = PositionType.SPACE, .value = '.' });
                                col_idx += 1;
                            },
                            '.' => {
                                const position = Position(isize).init(@as(isize, @intCast(row_idx)), @as(isize, @intCast(col_idx)));
                                const next_position = Position(isize).init(position.row, position.col + 1);
                                try map_row.append(MapPosition{ .position = position, .type = PositionType.SPACE, .value = e });
                                try map_row.append(MapPosition{ .position = next_position, .type = PositionType.SPACE, .value = e });
                                col_idx += 1;
                            },
                            else => unreachable,
                        }
                        col_idx += 1;
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
    displayMap(&map);
    var debug_it: usize = 0;
    for (moves) |move| {
        print("\n", .{});
        print("Move: {c}\n", .{move});
        try moveRobot(&map, move, &current_position, allocator);
        displayMap(&map);
        debug_it += 1;
        if (debug_it == 5) break;
    }
    //const ans = sumGPS(u32, &map);
    //print("Part 2: {d}\n", .{ans});
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
            print("{c}", .{map_position.value});
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
            while (next_next.type == PositionType.BOX) {
                // For NORTH and SOUTH
                // grab everything horizontally
                if ((offset.row == -1 and offset.col == 0) or (offset.row == 1 and offset.col == 0)) {
                    const n = map.items[0].items.len;
                    for (0..n) |i| {
                        const row_map = &map.items[@as(usize, @intCast(maybe_next.position.row))].items[i];
                        if (row_map.position.col == maybe_next.position.col) continue;
                        if (row_map.type == PositionType.BOX) try boxes.append(row_map);

                        const row_map_2 = &map.items[@as(usize, @intCast(next_next.position.row))].items[i];
                        if (row_map_2.position.col == next_next.position.col) continue;
                        if (row_map_2.type == PositionType.BOX) try boxes.append(row_map_2);
                    }
                }
                try boxes.append(next_next);
                next_next = &map.items[@as(usize, @intCast(next_next.position.row + offset.row))].items[@as(usize, @intCast(next_next.position.col + offset.col))];
                if (next_next.type == PositionType.WALL) return;
                // For NORTH and SOUTH
                // check if there is a wall horizontally
                if ((offset.row == -1 and offset.col == 0) or (offset.row == 1 and offset.col == 0)) {
                    const n = map.items[0].items.len;
                    var in_range = false;
                    for (0..n) |i| {
                        const row_map = &map.items[@as(usize, @intCast(next_next.position.row))].items[i];
                        if (offset.row == -1 and offset.col == 0) {
                            const below_row_map = &map.items[@as(usize, @intCast(next_next.position.row + 1))].items[i];
                            if (below_row_map.type == PositionType.BOX) {
                                in_range = true;
                            } else {
                                in_range = false;
                            }
                        } else {
                            const above_row_map = &map.items[@as(usize, @intCast(next_next.position.row - 1))].items[i];
                            if (above_row_map.type == PositionType.BOX) {
                                in_range = true;
                            } else {
                                in_range = false;
                            }
                        }
                        if (row_map.type == PositionType.WALL and in_range) return;
                    }
                }
            }
            loop_box: while (boxes.popOrNull()) |box| {
                var next_to_box = &map.items[@as(usize, @intCast(box.position.row + offset.row))].items[@as(usize, @intCast(box.position.col + offset.col))];
                var box_map = &map.items[@as(usize, @intCast(box.position.row))].items[@as(usize, @intCast(box.position.col))];
                var box_map_right = &map.items[@as(usize, @intCast(box.position.row))].items[@as(usize, @intCast(box.position.col + 1))];
                var box_map_left = &map.items[@as(usize, @intCast(box.position.row))].items[@as(usize, @intCast(box.position.col - 1))];
                switch (next_to_box.type) {
                    PositionType.ROBOT => unreachable,
                    PositionType.BOX => unreachable,
                    PositionType.WALL => break :loop_box,
                    PositionType.SPACE => {
                        if (offset.row == -1 and offset.col == 0 or (offset.row == 1 and offset.col == 0)) {
                            print("{any}\n", .{boxes.items});
                            switch (box_map.value) {
                                '[' => {
                                    var next_to_box_right = &map.items[@as(usize, @intCast(box.position.row + offset.row))].items[@as(usize, @intCast(box.position.col + offset.col + 1))];
                                    if (next_to_box_right.type == PositionType.SPACE) {
                                        next_to_box_right.type = PositionType.BOX;
                                        next_to_box_right.value = box_map_right.value;
                                        box_map_right.type = PositionType.SPACE;
                                        box_map_right.value = '.';
                                    }
                                },
                                ']' => {
                                    var next_to_box_left = &map.items[@as(usize, @intCast(box.position.row + offset.row))].items[@as(usize, @intCast(box.position.col + offset.col - 1))];
                                    if (next_to_box_left.type == PositionType.SPACE) {
                                        next_to_box_left.type = PositionType.BOX;
                                        next_to_box_left.value = box_map_left.value;
                                        box_map_left.type = PositionType.SPACE;
                                        box_map_left.value = '.';
                                    }
                                },
                                else => unreachable,
                            }
                        }
                        next_to_box.type = PositionType.BOX;
                        next_to_box.value = box_map.value;
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
