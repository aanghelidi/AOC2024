const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const print = std.debug.print;

const utils = @import("utils.zig");

const data = @embedFile("day023/input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = mem.tokenizeScalar(u8, data, '\n');
    var graph = std.StringArrayHashMap(std.ArrayList([]const u8)).init(allocator);
    defer graph.deinit();

    while (it.next()) |line| {
        var from_to_splitter = mem.splitScalar(u8, line, '-');
        const from = from_to_splitter.next().?;
        const to = from_to_splitter.next().?;
        if (graph.get(from)) |nodes| {
            var new_nodes = try nodes.clone();
            try new_nodes.append(to);
            try graph.put(from, new_nodes);
        } else {
            var nodes = std.ArrayList([]const u8).init(allocator);
            try nodes.append(to);
            try graph.put(from, nodes);
        }
        if (graph.get(to)) |nodes| {
            var new_nodes = try nodes.clone();
            try new_nodes.append(from);
            try graph.put(to, new_nodes);
        } else {
            var nodes = std.ArrayList([]const u8).init(allocator);
            try nodes.append(from);
            try graph.put(to, nodes);
        }
    }

    var three_pcs = std.StringArrayHashMap(void).init(allocator);
    defer three_pcs.deinit();
    var graph_it = graph.iterator();
    while (graph_it.next()) |entry| {
        const from = entry.key_ptr.*;
        const neightbours = entry.value_ptr.*;
        for (neightbours.items, 0..) |to1, i| {
            for (neightbours.items[i + 1 ..]) |to2| {
                if (graph.get(to1)) |to_1_neighbours| {
                    for (to_1_neighbours.items) |to_1_neighbour| {
                        if (std.mem.eql(u8, to_1_neighbour, to2)) {
                            var set_3: [3][]const u8 = .{ from, to1, to2 };
                            std.mem.sort([]const u8, &set_3, {}, strAsc);
                            const set_3_str = try std.fmt.allocPrint(allocator, "{s}", .{set_3});
                            if (three_pcs.contains(set_3_str)) continue;
                            try three_pcs.put(set_3_str, {});
                        }
                    }
                }
            }
        }
    }
    var ans: u32 = 0;
    for (three_pcs.keys()) |s| {
        const trimmed_s = std.mem.trim(u8, s, "{ }");
        var it_pc = std.mem.splitSequence(u8, trimmed_s, ", ");
        const pc_1 = it_pc.next().?;
        const pc_2 = it_pc.next().?;
        const pc_3 = it_pc.next().?;
        if (std.mem.startsWith(u8, pc_1, "t") or std.mem.startsWith(u8, pc_2, "t") or std.mem.startsWith(u8, pc_3, "t")) {
            ans += 1;
        }
    }
    print("Part 1: {d}\n", .{ans});

    var visited = std.StringHashMap(void).init(allocator);
    defer visited.deinit();
    var largest_component = std.ArrayList([]const u8).init(allocator);
    defer largest_component.deinit();
    graph_it.reset();

    while (graph_it.next()) |entry| {
        const node = entry.key_ptr.*;
        if (!visited.contains(node)) {
            var component = std.ArrayList([]const u8).init(allocator);
            defer component.deinit();

            try bfs(node, &graph, &visited, &component, allocator);

            if (component.items.len > largest_component.items.len) {
                largest_component.clearRetainingCapacity();
                try largest_component.appendSlice(component.items);
            }
        }
    }
    std.mem.sort([]const u8, largest_component.items, {}, strAsc);
    print("Part 2: ", .{});
    for (largest_component.items, 0..) |item, i| {
        if (i > 0) print(",", .{});
        print("{s}", .{item});
    }
}

fn bfs(node: []const u8, graph: *std.StringArrayHashMap(std.ArrayList([]const u8)), visited: *std.StringHashMap(void), component: *std.ArrayList([]const u8), allocator: Allocator) !void {
    const fifo = std.fifo.LinearFifo([]const u8, .Dynamic);
    var queue: fifo = fifo.init(allocator);
    defer queue.deinit();
    try queue.writeItem(node);
    try visited.put(node, {});
    while (queue.readItem()) |current_node| {
        try component.append(current_node);

        if (graph.get(current_node)) |neighbours| {
            for (neighbours.items) |neighbour| {
                if (visited.contains(neighbour)) continue;
                try visited.put(neighbour, {});
                try queue.writeItem(neighbour);
            }
        }
    }
}

fn strAsc(context: void, a: []const u8, b: []const u8) bool {
    _ = context;
    return std.mem.order(u8, a, b) == .lt;
}
