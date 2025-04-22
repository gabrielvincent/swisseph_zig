const std = @import("std");
const sweph = @cImport({
    // Include the swisseph header
    @cInclude("swephexp.h");
});

pub const SE = enum(c_int) {
    SUN = sweph.SE_SUN,
    _,
};

pub const SEFLG = enum(c_int) {
    JPLEPH = sweph.SEFLG_JPLEPH,
    _,
};

pub const SweError = error{
    InternalError,
    InvalidPlanet,
    InvalidFlag,
};

// swe_calc_ut

pub const SweCalcUtOut = struct {
    lon: f64,
    lat: f64,
    distance: f64,
    lon_speed: f64,
    lat_speed: f64,
    distance_speed: f64,
};

// Then modify your function to return an error union
pub fn swe_calc_ut(tjd_ut: f64, pl: SE, flag: SEFLG) SweError!SweCalcUtOut {
    var results: [6]f64 = undefined;

    var serr: [256]u8 = undefined;
    @memset(&serr, 0);

    const ipl = @intFromEnum(pl);
    const iflag = @intFromEnum(flag);

    const ret_flag = sweph.swe_calc_ut(tjd_ut, ipl, iflag, &results, &serr);

    // Check the result and return an appropriate error
    if (ret_flag < 0) {
        std.debug.print("error: {s}", .{serr});
        return SweError.InternalError;
    }

    // If no error, return void
    return SweCalcUtOut{
        .lon = results[0],
        .lat = results[1],
        .distance = results[2],
        .lon_speed = results[3],
        .lat_speed = results[4],
        .distance_speed = results[5],
    };
}
