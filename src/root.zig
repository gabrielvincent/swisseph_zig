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
};

pub fn heliacalUt(tjd_start_ut: f64, geopos: []const f64, datm: []const f64, dobs: []const f64, object_name: []const u8, type_event: i32, iflag: i32) SweError!f64 {
    var dret: [50]f64 = undefined;
    var serr: [256]u8 = undefined;
    @memset(&serr, 0);

    const ret_flag = sweph.swe_heliacal_ut(tjd_start_ut, geopos.ptr, datm.ptr, dobs.ptr, object_name.ptr, type_event, iflag, &dret, &serr);

    if (ret_flag < 0) {
        return .InternalError;
    }

    return dret;
}

pub fn heliacalPhenoUt(tjd_ut: f64, geopos: []const f64, datm: []const f64, dobs: []const f64, object_name: []const u8, type_event: i32, helflag: i32) SweError![]f64 {
    var darr: [50]f64 = undefined;
    var serr: [256]u8 = undefined;
    @memset(&serr, 0);

    const ret_flag = sweph.swe_heliacal_pheno_ut(tjd_ut, geopos.ptr, datm.ptr, dobs.ptr, object_name.ptr, type_event, helflag, &darr, &serr);

    if (ret_flag < 0) {
        return .InternalError;
    }

    return darr;
}

// swe_calc

pub const SweCalcUt = struct {
    lon: f64,
    lat: f64,
    distance: f64,
    lon_speed: f64,
    lat_speed: f64,
    distance_speed: f64,
};

pub fn calc(tjd_ut: f64, pl: SE, flag: SEFLG) SweError!SweCalcUt {
    var results: [6]f64 = undefined;

    var serr: [256]u8 = undefined;
    @memset(&serr, 0);

    const ipl = @intFromEnum(pl);
    const iflag = @intFromEnum(flag);

    const ret_flag = sweph.swe_calc_ut(tjd_ut, ipl, iflag, &results, &serr);

    if (ret_flag < 0) {
        return SweError.InternalError;
    }

    return SweCalcUt{
        .lon = results[0],
        .lat = results[1],
        .distance = results[2],
        .lon_speed = results[3],
        .lat_speed = results[4],
        .distance_speed = results[5],
    };
}

// swe_calc_ut

pub fn calc_ut(tjd_ut: f64, pl: SE, flag: SEFLG) SweError!SweCalcUt {
    var results: [6]f64 = undefined;

    var serr: [256]u8 = undefined;
    @memset(&serr, 0);

    const ipl = @intFromEnum(pl);
    const iflag = @intFromEnum(flag);

    const ret_flag = sweph.swe_calc_ut(tjd_ut, ipl, iflag, &results, &serr);

    if (ret_flag < 0) {
        return SweError.InternalError;
    }

    return SweCalcUt{
        .lon = results[0],
        .lat = results[1],
        .distance = results[2],
        .lon_speed = results[3],
        .lat_speed = results[4],
        .distance_speed = results[5],
    };
}
