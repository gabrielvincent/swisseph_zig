const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn split(allocator: Allocator, str: []const u8, delimiter: []const u8) !std.ArrayList([]const u8) {
    var iterator = std.mem.splitSequence(u8, str, delimiter);
    var parts = std.ArrayList([]const u8).init(allocator);

    while (iterator.next()) |part| {
        try parts.append(part);
    }

    return parts;
}

pub fn strSliceToFixed(slice: []const u8, comptime size: usize) [size]u8 {
    var buf: [size]u8 = undefined;
    @memcpy(buf[0..slice.len], slice);
    buf[slice.len] = 0;
    return buf;
}
