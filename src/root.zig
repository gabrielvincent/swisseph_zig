const std = @import("std");
const sweph = @cImport({
    // Include the swisseph header
    @cInclude("swephexp.h");
});

pub const SweError = error{
    InternalError,
};

pub fn heliacalUt(
    tjd_start_ut: f64,
    geopos: []const f64,
    datm: []const f64,
    dobs: []const f64,
    object_name: []const u8,
    type_event: i32,
    iflag: i32,
) SweError!f64 {
    var dret: [50]f64 = undefined;
    var serr: [256]u8 = undefined;

    const ret_flag = sweph.swe_heliacal_ut(
        tjd_start_ut,
        geopos.ptr,
        datm.ptr,
        dobs.ptr,
        object_name.ptr,
        type_event,
        iflag,
        &dret,
        &serr,
    );

    if (ret_flag < 0) {
        return .InternalError;
    }

    return dret;
}

pub fn heliacalPhenoUt(
    tjd_ut: f64,
    geopos: []const f64,
    datm: []const f64,
    dobs: []const f64,
    object_name: []const u8,
    type_event: i32,
    helflag: i32,
) SweError![]f64 {
    var darr: [50]f64 = undefined;
    var serr: [256]u8 = undefined;

    const ret_flag = sweph.swe_heliacal_pheno_ut(
        tjd_ut,
        geopos.ptr,
        datm.ptr,
        dobs.ptr,
        object_name.ptr,
        type_event,
        helflag,
        &darr,
        &serr,
    );

    if (ret_flag < 0) {
        return .InternalError;
    }

    return darr;
}

pub fn vis_limit_mag(
    tjdut: f64,
    geopos: []const f64,
    datm: []const f64,
    dobs: []const f64,
    object_name: []const u8,
    helflag: i32,
) SweError!f64 {
    var dret: [50]f64 = undefined;
    var serr: [256]u8 = undefined;

    const ret_flag = sweph.swe_vis_limit_mag(tjdut, geopos.ptr, datm.ptr, dobs.ptr, object_name.ptr, helflag, &dret, &serr);

    if (ret_flag < 0) {
        return .InternalError;
    }

    return dret;
}

pub fn heliacalAngle(
    tjd_ut: f64,
    geo: []f64,
    atm: []f64,
    obs: []f64,
    helflag: i32,
    mag: f64,
    azi_obj: f64,
    azi_sun: f64,
    azi_moon: f64,
    alt_moon: f64,
) SweError![]f64 {
    var result: f64 = undefined;

    var serr: [256]u8 = undefined;

    const iflag = @intFromEnum(helflag);

    const ret_flag = sweph.swe_heliacal_angle(
        tjd_ut,
        geo.ptr,
        atm.ptr,
        obs.ptr,
        iflag,
        mag,
        azi_obj,
        azi_sun,
        azi_moon,
        alt_moon,
        &result,
        &serr,
    );

    if (ret_flag < 0) {
        return SweError.InternalError;
    }

    return result;
}

pub fn topo_arcus_visionis(
    tjdut: f64,
    dgeo: []const f64,
    datm: []const f64,
    dobs: []const f64,
    helflag: i32,
    mag: f64,
    azi_obj: f64,
    alt_obj: f64,
    azi_sun: f64,
    azi_moon: f64,
    alt_moon: f64,
) SweError!f64 {
    var dret: f64 = undefined;
    var serr: [256]u8 = undefined;

    const ret_flag = sweph.swe_topo_arcus_visionis(
        tjdut,
        dgeo.ptr,
        datm.ptr,
        dobs.ptr,
        helflag,
        mag,
        azi_obj,
        alt_obj,
        azi_sun,
        azi_moon,
        alt_moon,
        &dret,
        &serr,
    );

    if (ret_flag < 0) {
        return .InternalError;
    }

    return dret;
}

pub fn set_astro_models(
    samod: []const u8,
    iflag: i32,
) void {
    sweph.swe_set_astro_models(samod.ptr, iflag);
}

pub fn get_astro_models(
    samod: []u8,
    sdet: []u8,
    iflag: i32,
) void {
    sweph.swe_get_astro_models(samod.ptr, sdet.ptr, iflag);
}

pub fn version(
    s: ?[]u8,
) [*:0]const u8 {
    return sweph.swe_version(if (s) |v| v.ptr else null);
}

pub fn get_library_path() []const u8 {
    var path_buffer: [256]u8 = undefined;
    @memset(&path_buffer, 0);

    const path_ptr = sweph.swe_get_library_path(&path_buffer);

    // If path_ptr is null, return an empty slice
    if (path_ptr == null) {
        return "";
    }

    // Convert C string to Zig string slice
    // Find the null terminator
    var len: usize = 0;
    while (path_buffer[len] != 0 and len < path_buffer.len) {
        len += 1;
    }

    return path_buffer[0..len];
}

pub const CalUtOut = struct {
    lon: f64,
    lat: f64,
    distance: f64,
    lon_speed: f64,
    lat_speed: f64,
    distance_speed: f64,
};

pub fn calc(tjd_ut: f64, pl: i32, flag: i32) SweError!CalUtOut {
    var xxret: [6]f64 = undefined;

    var serr: [256]u8 = undefined;

    const ipl = @intFromEnum(pl);
    const iflag = @intFromEnum(flag);

    const ret_flag = sweph.swe_calc_ut(tjd_ut, ipl, iflag, &xxret, &serr);

    if (ret_flag < 0) {
        return SweError.InternalError;
    }

    return CalUtOut{
        .lon = xxret[0],
        .lat = xxret[1],
        .distance = xxret[2],
        .lon_speed = xxret[3],
        .lat_speed = xxret[4],
        .distance_speed = xxret[5],
    };
}

pub fn calc_ut(tjd_ut: f64, pl: i32, flag: i32) SweError!CalUtOut {
    var xxret: [6]f64 = undefined;

    var serr: [256]u8 = undefined;

    const ipl = @intFromEnum(pl);
    const iflag = @intFromEnum(flag);

    const ret_flag = sweph.swe_calc_ut(tjd_ut, ipl, iflag, &xxret, &serr);

    if (ret_flag < 0) {
        return SweError.InternalError;
    }

    return CalUtOut{
        .lon = xxret[0],
        .lat = xxret[1],
        .distance = xxret[2],
        .lon_speed = xxret[3],
        .lat_speed = xxret[4],
        .distance_speed = xxret[5],
    };
}

pub fn calc_pctr(
    tjd: f64,
    ipl: i32,
    iplctr: i32,
    iflag: i32,
) SweError!CalUtOut {
    var xxret: [6]f64 = undefined;
    var serr: [256]u8 = undefined;

    const ret_flag = sweph.swe_calc_pctr(
        tjd,
        ipl,
        iplctr,
        iflag,
        &xxret,
        &serr,
    );

    if (ret_flag < 0) {
        return .InternalError;
    }

    return CalUtOut{
        .lon = xxret[0],
        .lat = xxret[1],
        .distance = xxret[2],
        .lon_speed = xxret[3],
        .lat_speed = xxret[4],
        .distance_speed = xxret[5],
    };
}

pub fn solcross(
    x2cross: f64,
    jd_et: f64,
    flag: i32,
) SweError!f64 {
    var serr: [256]u8 = undefined;

    const result = sweph.swe_solcross(
        x2cross,
        jd_et,
        flag,
        &serr,
    );

    if (serr != undefined) {
        return .InternalError;
    }

    return result;
}

pub fn solcross_ut(
    x2cross: f64,
    jd_et: f64,
    flag: i32,
) SweError!f64 {
    var serr: [256]u8 = undefined;

    const result = sweph.swe_solcross_ut(
        x2cross,
        jd_et,
        flag,
        &serr,
    );

    if (serr != undefined) {
        return .InternalError;
    }

    return result;
}

pub fn mooncross(
    x2cross: f64,
    jd_et: f64,
    flag: i32,
) SweError!f64 {
    var serr: [256]u8 = undefined;

    const result = sweph.swe_mooncross(
        x2cross,
        jd_et,
        flag,
        &serr,
    );

    if (serr != undefined) {
        return .InternalError;
    }

    return result;
}

pub fn mooncross_ut(
    x2cross: f64,
    jd_et: f64,
    flag: i32,
) SweError!f64 {
    var serr: [256]u8 = undefined;

    const result = sweph.swe_mooncross_ut(
        x2cross,
        jd_et,
        flag,
        &serr,
    );

    if (serr != undefined) {
        return .InternalError;
    }

    return result;
}

pub fn mooncross_node(
    jd_et: f64,
    flag: i32,
) SweError!struct { jd: f64, lon: f64, lat: f64 } {
    var xlon: f64 = undefined;
    var xlat: f64 = undefined;
    var serr: [256]u8 = undefined;

    const jd = sweph.swe_mooncross_node(
        jd_et,
        flag,
        &xlon,
        &xlat,
        &serr,
    );

    if (serr != undefined) {
        return .InternalError;
    }

    return .{
        .jd = jd,
        .lon = xlon,
        .lat = xlat,
    };
}

pub fn mooncross_node_ut(
    jd_ut: f64,
    flag: i32,
) SweError!struct { jd: f64, lon: f64, lat: f64 } {
    var xlon: f64 = undefined;
    var xlat: f64 = undefined;
    var serr: [256]u8 = undefined;

    const jd = sweph.swe_mooncross_node_ut(
        jd_ut,
        flag,
        &xlon,
        &xlat,
        &serr,
    );

    if (serr != undefined) {
        return .InternalError;
    }

    return .{
        .jd = jd,
        .lon = xlon,
        .lat = xlat,
    };
}
