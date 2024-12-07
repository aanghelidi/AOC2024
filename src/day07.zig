const std = @import("std");
const Allocator = std.mem.Allocator;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day07/input.txt");
const parseInt = std.fmt.parseInt;

const Equation = struct { test_result: u64, numbers: []u64 };

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const equations = parse(data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer equations.deinit();
    const ans = solve(equations, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    print("Part 1: {d}\n", .{ans[0]});
    print("Part 2: {d}\n", .{ans[1]});
}

fn parse(input: []const u8, allocator: Allocator) !std.ArrayList(Equation) {
    var equations = std.ArrayList(Equation).init(allocator);
    var it = mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |row| {
        var it_parts = mem.splitSequence(u8, row, ": ");
        if (it_parts.next()) |left| {
            if (it_parts.next()) |right| {
                const test_result = try parseInt(u64, left, 10);
                const numbers = try utils.positiveInts(u64, right, allocator);
                const equation = Equation{ .test_result = test_result, .numbers = numbers.items };
                try equations.append(equation);
            }
        }
    }
    return equations;
}

fn solve(equations: std.ArrayList(Equation), allocator: Allocator) !struct { u64, u64 } {
    var result: u64 = 0;
    var result2: u64 = 0;
    for (equations.items) |eq| {
        const solved = try canBeSolved(eq, allocator);
        const solved2 = try canBeSolved2(eq, allocator);
        if (solved) result += eq.test_result;
        if (solved2) result2 += eq.test_result;
    }
    return .{ result, result2 };
}

fn canBeSolved(equation: Equation, allocator: Allocator) !bool {
    if (equation.numbers.len == 1) {
        return equation.numbers[0] == equation.test_result;
    }
    const head = equation.numbers[0];
    const tail = equation.numbers[1..];
    const mul_op = head * tail[0];
    const add_op = head + tail[0];

    const new_numbers = try std.mem.concat(allocator, u64, &[_][]const u64{
        &[_]u64{mul_op},
        tail[1..],
    });
    defer allocator.free(new_numbers);
    const new_eq1 = Equation{ .test_result = equation.test_result, .numbers = new_numbers };
    const try1 = try canBeSolved(new_eq1, allocator);
    if (try1) return true;

    const new_numbers2 = try std.mem.concat(allocator, u64, &[_][]const u64{
        &[_]u64{add_op},
        tail[1..],
    });
    defer allocator.free(new_numbers2);
    const new_eq2 = Equation{ .test_result = equation.test_result, .numbers = new_numbers2 };
    const try2 = try canBeSolved(new_eq2, allocator);
    if (try2) return true;

    return false;
}

fn canBeSolved2(equation: Equation, allocator: Allocator) !bool {
    if (equation.numbers.len == 1) {
        return equation.numbers[0] == equation.test_result;
    }
    const head = equation.numbers[0];
    const tail = equation.numbers[1..];

    const mul_op = head * tail[0];
    const add_op = head + tail[0];
    const concat_op_str = try std.fmt.allocPrint(allocator, "{d}{d}", .{ head, tail[0] });
    defer allocator.free(concat_op_str);
    const concat_op = try parseInt(u64, concat_op_str, 10);

    const new_numbers = try std.mem.concat(allocator, u64, &[_][]const u64{
        &[_]u64{mul_op},
        tail[1..],
    });
    defer allocator.free(new_numbers);
    const new_eq1 = Equation{ .test_result = equation.test_result, .numbers = new_numbers };
    const try1 = try canBeSolved2(new_eq1, allocator);
    if (try1) return true;

    const new_numbers2 = try std.mem.concat(allocator, u64, &[_][]const u64{
        &[_]u64{add_op},
        tail[1..],
    });
    defer allocator.free(new_numbers2);
    const new_eq2 = Equation{ .test_result = equation.test_result, .numbers = new_numbers2 };
    const try2 = try canBeSolved2(new_eq2, allocator);
    if (try2) return true;

    const new_numbers3 = try std.mem.concat(allocator, u64, &[_][]const u64{
        &[_]u64{concat_op},
        tail[1..],
    });
    defer allocator.free(new_numbers3);

    const new_eq3 = Equation{ .test_result = equation.test_result, .numbers = new_numbers3 };
    const try3 = try canBeSolved2(new_eq3, allocator);
    if (try3) return true;

    return false;
}

test "day 7 part 1 2024" {
    const testing_data = @embedFile("day07/sample.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_equations = parse(testing_data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer test_equations.deinit();

    const ans = solve(test_equations, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    try testing.expectEqual(3749, ans[0]);
}

test "day 7 part 2 2024" {
    const testing_data = @embedFile("day07/sample.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_equations = parse(testing_data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer test_equations.deinit();
    const ans = solve(test_equations, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    try testing.expectEqual(11387, ans[1]);
}
