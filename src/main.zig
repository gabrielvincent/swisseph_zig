const std = @import("std");
const sweph = @import("sweph.zig");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const julday: f64 = 2459000.5; // Example Julian day
    const eph = sweph.swe_calc_ut(julday, .SUN, .JPLEPH) catch |err| {
        std.debug.print("Failed to get ephemeris: {}", .{err});
        return;
    };

    try stdout.print("Sun position: {d:.6}\n", .{eph.lon});
    try stdout.print("Sun speed: {d:.6}\n", .{eph.lon_speed});
}
