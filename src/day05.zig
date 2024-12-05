const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const print = std.debug.print;
const data = @embedFile("day05/input.txt");
const parseInt = std.fmt.parseInt;

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const instruction = parse(data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer instruction.updates.deinit();
    defer instruction.rules.deinit();
    const right_updates = retrieveRightUpdates(instruction, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer right_updates.deinit();

    var ans: u32 = 0;
    for (right_updates.items) |update| {
        const n: u32 = @as(u32, @intCast(update.items.len));
        const pos = @divFloor(n, 2);
        ans += update.items[pos];
    }
    print("Part 1: {d}\n", .{ans});

    const wrong_updates = retrieveWrongUpdates(instruction, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer wrong_updates.deinit();

    var ans2: u32 = 0;
    for (wrong_updates.items) |update| {
        var all_update_rules = std.ArrayList(Rule).init(allocator);
        defer all_update_rules.deinit();
        for (update.items) |e| {
            const page_rules = pageRules(e, instruction.rules, update.items, allocator) catch |err| {
                print("{any}\n", .{err});
                return;
            };
            defer page_rules.deinit();
            all_update_rules.appendSlice(page_rules.items) catch |err| {
                print("{any}\n", .{err});
                return;
            };
        }

        var is_right = checkRules(all_update_rules, update.items);
        // TODO: probably should use std.sort.insertionContext here
        while (!is_right[0]) {
            const idx_before = mem.indexOf(u32, update.items, &[_]u32{is_right[1].before}).?;
            const idx_after = mem.indexOf(u32, update.items, &[_]u32{is_right[1].after}).?;
            mem.swap(u32, &update.items[idx_before], &update.items[idx_after]);
            is_right = checkRules(all_update_rules, update.items);
        }

        const n: u32 = @as(u32, @intCast(update.items.len));
        const pos = @divFloor(n, 2);
        ans2 += update.items[pos];
    }
    print("Part 2: {d}\n", .{ans2});
}

const Rule = struct { before: u32, after: u32 };

const Instruction = struct {
    rules: std.ArrayList(Rule),
    updates: std.ArrayList(std.ArrayList(u32)),
};

fn parse(input: []const u8, allocator: Allocator) !Instruction {
    var rules = std.ArrayList(Rule).init(allocator);
    var updates = std.ArrayList(std.ArrayList(u32)).init(allocator);

    var it_sections = mem.splitSequence(u8, input, "\n\n");
    var count: usize = 0;
    var raw_rules: []const u8 = undefined;
    var raw_updates: []const u8 = undefined;
    while (it_sections.next()) |part| {
        if (count == 0) raw_rules = part;
        if (count > 0) raw_updates = part;
        count += 1;
    }

    var it_rules = mem.tokenizeScalar(u8, raw_rules, '\n');
    while (it_rules.next()) |rule| {
        var it_rule = mem.splitScalar(u8, rule, '|');
        if (it_rule.next()) |before| {
            if (it_rule.next()) |after| {
                const before_parsed = try parseInt(u32, before, 10);
                const after_parsed = try parseInt(u32, after, 10);
                try rules.append(Rule{ .before = before_parsed, .after = after_parsed });
            }
        }
    }

    var it_updates = mem.tokenizeScalar(u8, raw_updates, '\n');
    while (it_updates.next()) |update| {
        var it_update = mem.splitScalar(u8, update, ',');
        var inner_update = std.ArrayList(u32).init(allocator);
        while (it_update.next()) |u| {
            const u_parsed = try parseInt(u32, u, 10);
            try inner_update.append(u_parsed);
        }
        try updates.append(inner_update);
    }

    return Instruction{ .rules = rules, .updates = updates };
}

fn retrieveRightUpdates(instruction: Instruction, allocator: Allocator) !std.ArrayList(std.ArrayList(u32)) {
    var right_updates = std.ArrayList(std.ArrayList(u32)).init(allocator);
    for (instruction.updates.items) |update| {
        var is_correct = true;

        for (update.items) |e| {
            const rules = try pageRules(e, instruction.rules, update.items, allocator);
            defer rules.deinit();
            const is_right = checkRules(rules, update.items);
            if (!is_right[0]) is_correct = false;
        }
        if (is_correct) try right_updates.append(update);
    }
    return right_updates;
}

fn retrieveWrongUpdates(instruction: Instruction, allocator: Allocator) !std.ArrayList(std.ArrayList(u32)) {
    var wrong_updates = std.ArrayList(std.ArrayList(u32)).init(allocator);
    for (instruction.updates.items) |update| {
        var is_correct = true;

        for (update.items) |e| {
            const rules = try pageRules(e, instruction.rules, update.items, allocator);
            defer rules.deinit();
            const is_right = checkRules(rules, update.items);
            if (!is_right[0]) is_correct = false;
        }
        if (!is_correct) try wrong_updates.append(update);
    }
    return wrong_updates;
}

fn pageRules(e: u32, rules: std.ArrayList(Rule), current: []u32, allocator: Allocator) !std.ArrayList(Rule) {
    var page_rules = std.ArrayList(Rule).init(allocator);
    for (rules.items) |rule| {
        if (e == rule.before and std.mem.containsAtLeast(u32, current, 1, &[_]u32{rule.after})) {
            try page_rules.append(rule);
        }
    }
    return page_rules;
}

fn checkRules(rules: std.ArrayList(Rule), current: []u32) struct { bool, Rule } {
    var is_correct = true;
    var broken_rule: Rule = undefined;
    for (rules.items) |rule| {
        const idx_before: u32 = @as(u32, @intCast(mem.indexOf(u32, current, &[_]u32{rule.before}).?));
        const idx_after: u32 = @as(u32, @intCast(mem.indexOf(u32, current, &[_]u32{rule.after}).?));
        if (idx_before > idx_after) {
            is_correct = false;
            broken_rule = rule;
            break;
        }
    }
    return .{ is_correct, broken_rule };
}
