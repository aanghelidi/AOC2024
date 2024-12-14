const std = @import("std");
const testing = std.testing;
const ascii = std.ascii;
const fmt = std.fmt;
const assert = std.debug.assert;
const math = std.math;

/// On success, returns the content of the file in a []u8.
/// On error, returns either `std.fs.Dir.StatFileError` or `std.fs.File.ReadError`.
pub fn readFile(filename: []const u8) ![]u8 {
    const stats = try std.fs.cwd().statFile(filename);
    const file_size = stats.size;
    const data = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, file_size);
    return data;
}

/// Basic pair
pub fn Pair(comptime T: type) type {
    return struct {
        const Self = @This();
        row: T,
        col: T,

        pub fn init(row: T, col: T) Self {
            return Self{
                .row = row,
                .col = col,
            };
        }
    };
}

/// Simple generic struct containing Position info.
pub fn Position(comptime T: type) type {
    return struct {
        const Self = @This();
        row: T,
        col: T,

        pub fn init(row: T, col: T) Self {
            return Self{
                .row = row,
                .col = col,
            };
        }

        pub fn N4(self: Self, allocator: std.mem.Allocator) !std.ArrayList(Self) {
            var list = std.ArrayList(Self).init(allocator);
            errdefer list.deinit();

            try list.append(Self.init(self.row + 1, self.col));
            try list.append(Self.init(self.row - 1, self.col));
            try list.append(Self.init(self.row, self.col + 1));
            try list.append(Self.init(self.row, self.col - 1));

            return list;
        }

        pub fn isEqual(self: Self, other: Self) bool {
            return self.row == other.row and self.col == other.col;
        }
    };
}

/// Given a []const u8 like a string returns whether or not it contains only digits.
pub fn allDigits(chars: []const u8) bool {
    if (chars.len == 0) return false;
    for (chars) |char| {
        if (!ascii.isDigit(char)) {
            return false;
        }
    }
    return true;
}

/// Parses a string and extracts all integers, including negative numbers.
///
/// This function scans the input string for sequences of digits, optionally preceded by a '-' sign,
/// and converts them into integers of type `T`. The integers are collected into an `ArrayList(T)`.
/// Returns an compile time error when `T` is not a signed integers.
pub fn ints(comptime T: type, text: []const u8, allocator: std.mem.Allocator) !std.ArrayList(T) {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .signed) {
        @compileError("`a` and `b` must be signed integers");
    }

    var nums = std.ArrayList(T).init(allocator);

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (!ascii.isDigit(text[i]) and text[i] != '-') continue;
        var is_negative = false;
        if (text[i] == '-') {
            is_negative = true;
            i += 1;
            if (i >= text.len or !ascii.isDigit(text[i])) continue;
        }
        const start = i;
        while (i < text.len and ascii.isDigit(text[i])) : (i += 1) {}
        const num_str = text[start..i];
        const num = try std.fmt.parseInt(T, num_str, 10);
        try nums.append(if (is_negative) -num else num);
    }

    return nums;
}

/// Parses a string and extracts all integers.
///
/// This function scans the input string for sequences of digits and converts them into integers of type `T`.
/// Only positive integers are collected into an `ArrayList(T)`. The function returns a compile time error
/// when `T` is not an unsigned integer.
pub fn positiveInts(comptime T: type, text: []const u8, allocator: std.mem.Allocator) !std.ArrayList(T) {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned) {
        @compileError("`T` must be a unsigned integer");
    }

    var nums = std.ArrayList(T).init(allocator);

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (!ascii.isDigit(text[i])) continue;
        const start = i;
        while (i < text.len and ascii.isDigit(text[i])) : (i += 1) {}
        const num_str = text[start..i];
        const num = try std.fmt.parseInt(T, num_str, 10);
        try nums.append(num);
    }

    return nums;
}

/// Parses a string and extracts all digits.
///
/// This function scans the input string for digits and converts them into integers of type `T`.
/// The function returns a compile time error when `T` is not an unsigned integer.
pub fn digits(comptime T: type, text: []const u8, allocator: std.mem.Allocator) !std.ArrayList(T) {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned) {
        @compileError("`T` must be a unsigned integer");
    }

    var nums = std.ArrayList(T).init(allocator);

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (!ascii.isDigit(text[i])) continue;
        const num = text[i] - '0';
        try nums.append(num);
    }

    return nums;
}

test "Position can init" {
    const pos = Position(u8).init(0, 0);
    try testing.expectEqual(0, pos.row);
    try testing.expectEqual(0, pos.col);
}

test "Position get n4" {
    var pos = Position(isize).init(2, 3);
    const allocator = std.testing.allocator;
    const actual = try pos.N4(allocator);
    defer actual.deinit();
    const pos1 = Position(isize).init(3, 3);
    const pos2 = Position(isize).init(1, 3);
    const pos3 = Position(isize).init(2, 4);
    const pos4 = Position(isize).init(2, 2);

    try testing.expect(pos1.isEqual(actual.items[0]));
    try testing.expect(pos2.isEqual(actual.items[1]));
    try testing.expect(pos3.isEqual(actual.items[2]));
    try testing.expect(pos4.isEqual(actual.items[3]));
}

test "allDigits scenarios" {
    try testing.expectEqual(false, allDigits("ab00"));
    try testing.expectEqual(false, allDigits(""));
    try testing.expectEqual(true, allDigits("0"));
    try testing.expectEqual(true, allDigits("12349"));
    try testing.expectEqual(false, allDigits("123.49"));
}

test "parsing ints" {
    var result = try ints(i16, "Here are some numbers: -42, 123, -567, 890, and -12.", testing.allocator);
    defer result.deinit();
    try std.testing.expectEqualSlices(i16, &[_]i16{ -42, 123, -567, 890, -12 }, result.items);

    var result_2 = try ints(i8, "1 2 3 4 5", testing.allocator);
    defer result_2.deinit();
    try std.testing.expectEqualSlices(i8, &[_]i8{ 1, 2, 3, 4, 5 }, result_2.items);

    var result_3 = try ints(i8, "-1 -2 -3 -4 -5", testing.allocator);
    defer result_3.deinit();
    try std.testing.expectEqualSlices(i8, &[_]i8{ -1, -2, -3, -4, -5 }, result_3.items);

    var result_4 = try ints(i8, "No numbers here!", testing.allocator);
    defer result_4.deinit();
    try std.testing.expectEqualSlices(i8, &[_]i8{}, result_4.items);

    var result_5 = try ints(i32, "1234567890", testing.allocator);
    defer result_5.deinit();
    try std.testing.expectEqualSlices(i32, &[_]i32{1234567890}, result_5.items);

    var result_6 = try ints(i16, "  123  456  789  ", testing.allocator);
    defer result_6.deinit();
    try std.testing.expectEqualSlices(i16, &[_]i16{ 123, 456, 789 }, result_6.items);

    var result_7 = try ints(i16, "123abc-456def789", testing.allocator);
    defer result_7.deinit();
    try std.testing.expectEqualSlices(i16, &[_]i16{ 123, -456, 789 }, result_7.items);

    // Should raise a compile time error
    // comptime {
    //     _ = ints(u32, "123", std.testing.allocator);
    // }
}

test "parsing positive ints" {
    var result = try positiveInts(u16, "Here are some numbers: -42, 123, -567, 890, and -12.", testing.allocator);
    defer result.deinit();
    try std.testing.expectEqualSlices(u16, &[_]u16{ 42, 123, 567, 890, 12 }, result.items);

    var result_2 = try positiveInts(u8, "1 2 3 4 5", testing.allocator);
    defer result_2.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, result_2.items);

    var result_3 = try positiveInts(u8, "-1 -2 -3 -4 -5", testing.allocator);
    defer result_3.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, result_3.items);

    var result_4 = try positiveInts(u8, "No numbers here!", testing.allocator);
    defer result_4.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{}, result_4.items);

    var result_5 = try positiveInts(u32, "1234567890", testing.allocator);
    defer result_5.deinit();
    try std.testing.expectEqualSlices(u32, &[_]u32{1234567890}, result_5.items);

    var result_6 = try positiveInts(u16, "  123  456  789  ", testing.allocator);
    defer result_6.deinit();
    try std.testing.expectEqualSlices(u16, &[_]u16{ 123, 456, 789 }, result_6.items);

    var result_7 = try positiveInts(u16, "123abc-456def789", testing.allocator);
    defer result_7.deinit();
    try std.testing.expectEqualSlices(u16, &[_]u16{ 123, 456, 789 }, result_7.items);

    // Should raise a compile time error
    // comptime {
    //     _ = positiveInts(i32, "123", std.testing.allocator);
    // }
}

test "parsing digits" {
    var result = try digits(u8, "Here are some numbers: -42, 123, -567, 890, and -12.", testing.allocator);
    defer result.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{ 4, 2, 1, 2, 3, 5, 6, 7, 8, 9, 0, 1, 2 }, result.items);

    var result_2 = try digits(u8, "1 2 3 4 5", testing.allocator);
    defer result_2.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, result_2.items);

    var result_3 = try digits(u8, "-1 -2 -3 -4 -5", testing.allocator);
    defer result_3.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5 }, result_3.items);

    var result_4 = try digits(u8, "No numbers here!", testing.allocator);
    defer result_4.deinit();
    try std.testing.expectEqualSlices(u8, &[_]u8{}, result_4.items);

    var result_5 = try digits(u32, "1234567890", testing.allocator);
    defer result_5.deinit();
    try std.testing.expectEqualSlices(u32, &[_]u32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 }, result_5.items);

    var result_6 = try digits(u16, "  123  456  789  ", testing.allocator);
    defer result_6.deinit();
    try std.testing.expectEqualSlices(u16, &[_]u16{ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, result_6.items);

    var result_7 = try digits(u16, "123abc-456def789", testing.allocator);
    defer result_7.deinit();
    try std.testing.expectEqualSlices(u16, &[_]u16{ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, result_7.items);

    // Should raise a compile time error
    // comptime {
    //     _ = digits(i32, "123", std.testing.allocator);
    // }
}
