const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const utils = @import("utils.zig");
const sweph = @cImport({
    // Include the swisseph header
    @cInclude("swephexp.h");
});

const SweRetFlag = enum(i32) {
    BEYOND_EPH_LIMITS = -3,
    NOT_AVAILABLE = -2,
    ERR = -1,
    OK = 0,
};

const SweErr = error{
    Unknown,
    CalcFailure,
    OutOfMemory,
    NotFound,
    InvalidDate,
};

pub const CalendarFlag = enum(u8) {
    g = 'g',
    j = 'j',
};

pub const Diagnostics = struct {
    allocator: std.mem.Allocator,
    _err: ?[]u8 = null,

    pub fn init(allocator: Allocator) Diagnostics {
        return .{ .allocator = allocator };
    }

    fn setErrMsg(self: *@This(), msg: []const u8) !void {
        const str_len = std.mem.indexOfScalar(u8, msg, 0) orelse msg.len;

        if (self._err) |err| {
            self._err = try self.allocator.realloc(err, str_len);
        } else {
            self._err = try self.allocator.alloc(u8, str_len);
        }

        @memcpy(self._err.?[0..str_len], msg[0..str_len]);
    }

    pub fn errMsg(self: *const @This()) []const u8 {
        if (self._err) |err| {
            const ret: []const u8 = err;
            return ret;
        }
        return "";
    }

    fn deinit(self: *@This()) void {
        if (self._err) |err| self.allocator.free(err);
    }
};

pub const HeliacalUtOut = struct {
    visibility_start_jd: f64,
    visibility_optimum_jd: f64,
    visibility_end_jd: f64,
};

pub fn heliacalUt(
    jd_start: f64,
    geo: [3]f64, // longitude, latitude, altitude
    atm: [4]f64, // pressure, temperature, humidity, etc.
    obs: [6]f64, // observer parameters
    object_name: []const u8,
    event_type: i32,
    helflag: i32,
    diags: ?*Diagnostics,
) SweErr!HeliacalUtOut {
    var dret: [50]f64 = undefined; // Array to store results
    var err_buf: [256:0]u8 = undefined;

    var object_name_buf = utils.strSliceToFixed(object_name, 256);

    const ret_val = sweph.swe_heliacal_ut(
        jd_start,
        @constCast(&geo),
        @constCast(&atm),
        @constCast(&obs),
        &object_name_buf,
        event_type,
        helflag,
        &dret,
        &err_buf,
    );

    if (ret_val < 0) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return HeliacalUtOut{
        .visibility_start_jd = dret[0],
        .visibility_optimum_jd = dret[1],
        .visibility_end_jd = dret[2],
    };
}

test "heliacalUt" {
    setEphePath("ephe");

    const jd: f64 = 2449090.1145833;
    const geo: [3]f64 = .{ 0, 0, 0 };
    const atm: [4]f64 = .{ 0, 0, 0, 0 };
    const obs: [6]f64 = .{ 0, 0, 0, 0, 0, 0 };
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const hel = try heliacalUt(
        jd,
        geo,
        atm,
        obs,
        "mars",
        sweph.SE_HELIACAL_RISING,
        sweph.SE_HELFLAG_HIGH_PRECISION,
        &diags,
    );

    const expected = HeliacalUtOut{
        .visibility_start_jd = 2.4494357236005506e6,
        .visibility_optimum_jd = 2.449435725961661e6,
        .visibility_end_jd = 2.449435727176938e6,
    };
    try std.testing.expectEqual(expected, hel);
}

const HeliacalPhenoUtOut = struct {
    alt_obj: f64,
    app_alt_obj: f64,
    geo_alt_obj: f64,
    azi_obj: f64,
    alt_sun: f64,
    azi_sun: f64,
    tav_act: f64,
    arcv_act: f64,
    daz_act: f64,
    arcl_act: f64,
    k_act: f64,
    min_tav: f64,
    t_first_vr: f64,
    t_b_vr: f64,
    t_last_vr: f64,
    t_b_yallop: f64,
    w_moon: f64,
    q_yal: f64,
    q_crit: f64,
    par_obj: f64,
    magn_obj: f64,
    rise_obj: f64,
    rise_sun: f64,
    lag: f64,
    tvis_vr: f64,
    l_moon: f64,
};

pub fn heliacalPhenoUt(
    jd_start: f64,
    geo: [3]f64, // longitude, latitude, altitude
    atm: [4]f64, // pressure, temperature, humidity, etc.
    obs: [6]f64, // observer parameters
    object_name: []const u8,
    event_type: i32,
    helflag: i32,
    diags: ?*Diagnostics,
) SweErr!HeliacalPhenoUtOut {
    var dret: [50]f64 = undefined; // Array to store results
    var err_buf: [256:0]u8 = undefined;

    var obj_name_buf: [256]u8 = undefined;
    @memcpy(obj_name_buf[0..object_name.len], object_name);
    obj_name_buf[object_name.len] = 0;
    const c_object_name = &obj_name_buf;

    const ret_flag = sweph.swe_heliacal_pheno_ut(
        jd_start,
        @constCast(&geo),
        @constCast(&atm),
        @constCast(&obs),
        c_object_name,
        event_type,
        helflag,
        &dret,
        &err_buf,
    );

    if (ret_flag < 0) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return HeliacalPhenoUtOut{
        .alt_obj = dret[0],
        .app_alt_obj = dret[1],
        .geo_alt_obj = dret[2],
        .azi_obj = dret[3],
        .alt_sun = dret[4],
        .azi_sun = dret[5],
        .tav_act = dret[6],
        .arcv_act = dret[7],
        .daz_act = dret[8],
        .arcl_act = dret[9],
        .k_act = dret[10],
        .min_tav = dret[11],
        .t_first_vr = dret[12],
        .t_b_vr = dret[13],
        .t_last_vr = dret[14],
        .t_b_yallop = dret[15],
        .w_moon = dret[16],
        .q_yal = dret[17],
        .q_crit = dret[18],
        .par_obj = dret[19],
        .magn_obj = dret[20],
        .rise_obj = dret[21],
        .rise_sun = dret[22],
        .lag = dret[23],
        .tvis_vr = dret[24],
        .l_moon = dret[25],
    };
}

test "heliacalPhenoUt" {
    setEphePath("ephe");

    const jd: f64 = 2449090.1145833;
    const geo: [3]f64 = .{ 0, 0, 0 };
    const atm: [4]f64 = .{ 0, 0, 0, 0 };
    const obs: [6]f64 = .{ 0, 0, 0, 0, 0, 0 };
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const hel = try heliacalPhenoUt(
        jd,
        geo,
        atm,
        obs,
        "mars",
        sweph.SE_HELIACAL_RISING,
        sweph.SE_HELFLAG_HIGH_PRECISION,
        &diags,
    );

    const expected = HeliacalPhenoUtOut{
        .alt_obj = 3.322064816559828e1,
        .app_alt_obj = 3.324500295804901e1,
        .geo_alt_obj = 3.322223525931041e1,
        .azi_obj = 6.1251302960950966e1,
        .alt_sun = 4.8157630323795594e1,
        .azi_sun = 2.8330401018728065e2,
        .tav_act = -1.4936982158197317e1,
        .arcv_act = -1.4935395064485185e1,
        .daz_act = 2.220527072263297e2,
        .arcl_act = 1.3584386571887987e2,
        .k_act = 3.310282416045371e-1,
        .min_tav = 0e0,
        .t_first_vr = 2.44909001087977e6,
        .t_b_vr = 9.9999999e7,
        .t_last_vr = 9.9999999e7,
        .t_b_yallop = 9.9999999e7,
        .w_moon = 0e0,
        .q_yal = 0e0,
        .q_crit = 0e0,
        .par_obj = 1.5870937121320594e-3,
        .magn_obj = 7.754093864325826e-1,
        .rise_obj = 2.44909001087977e6,
        .rise_sun = 2.449090748776619e6,
        .lag = -7.378968489356339e-1,
        .tvis_vr = 9.9999999e7,
        .l_moon = 0e0,
    };
    try std.testing.expectEqual(expected, hel);
}

const Visibility = enum {
    BelowHorizon,
    PhotopicVision,
    ScotopicVision,
    NearLimit,
};

const VisLimitMagOut = struct {
    lim_visual_magnitude: f64,
    alt_obj: f64,
    azi_obj: f64,
    alt_sun: f64,
    azi_sun: f64,
    alt_moon: f64,
    azi_moon: f64,
    magn_obj: f64,
    visibility: Visibility,
};

pub fn visLimitMag(
    tjdut: f64,
    geo: [3]f64, // longitude, latitude, altitude
    atm: [4]f64, // pressure, temperature, humidity, etc.
    obs: [6]f64, // observer parameters
    object_name: []const u8,
    event_type: i32,
    helflag: i32,
    diags: ?*Diagnostics,
) SweErr!VisLimitMagOut {
    var darr: [8]f64 = undefined; // Array to store results
    var err_buf: [256:0]u8 = undefined;

    var obj_name_buf: [256]u8 = undefined;
    @memcpy(obj_name_buf[0..object_name.len], object_name);
    obj_name_buf[object_name.len] = 0;
    const c_object_name = &obj_name_buf;

    const ret_flag = sweph.swe_heliacal_pheno_ut(
        tjdut,
        @constCast(&geo),
        @constCast(&atm),
        @constCast(&obs),
        c_object_name,
        event_type,
        helflag,
        &darr,
        &err_buf,
    );

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    var visibility: Visibility = .BelowHorizon;
    if (ret_flag == 0) {
        visibility = .PhotopicVision;
    } else {
        if ((ret_flag & 1) != 0) {
            visibility = .ScotopicVision;
        } else if ((ret_flag & 2) != 0) {
            visibility = .NearLimit;
        }
    }

    return VisLimitMagOut{
        .lim_visual_magnitude = darr[0],
        .alt_obj = darr[1],
        .azi_obj = darr[2],
        .alt_sun = darr[3],
        .azi_sun = darr[4],
        .alt_moon = darr[5],
        .azi_moon = darr[6],
        .magn_obj = darr[7],
        .visibility = visibility,
    };
}

test "vis_limit_mag" {
    const jd: f64 = 2449090.1145833;
    const geo: [3]f64 = .{ 0, 100, 0 };
    const atm: [4]f64 = .{ 0, 0, 0, 0 };
    const obs: [6]f64 = .{ 0, 0, 1000, 30, 0, 0 };
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const limMag = try visLimitMag(
        jd,
        geo,
        atm,
        obs,
        "mars",
        sweph.SE_HELIACAL_RISING,
        sweph.SE_HELFLAG_HIGH_PRECISION,
        &diags,
    );

    const expected = VisLimitMagOut{
        .lim_visual_magnitude = 1.7522145145859408e1,
        .alt_obj = 1.7572461868203337e1,
        .azi_obj = 1.7523896634243343e1,
        .alt_sun = 1.2972415588934848e2,
        .azi_sun = 1.246872582204149e0,
        .alt_moon = 2.2049002826986566e2,
        .azi_moon = 1.627527256365526e1,
        .magn_obj = 1.6277024052039195e1,
        .visibility = .PhotopicVision,
    };

    try std.testing.expectEqual(expected, limMag);
}

pub fn heliacalAngle(
    tjdut: f64,
    geo: [3]f64, // longitude, latitude, altitude
    atm: [4]f64, // pressure, temperature, humidity, etc.
    obs: [6]f64, // observer parameters
    helflag: i32,
    mag: f64,
    azi_obj: f64,
    azi_sun: f64,
    azi_moon: f64,
    alt_moon: f64,
    diags: ?*Diagnostics,
) SweErr!f64 {
    var angle: f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_heliacal_angle(
        tjdut,
        @constCast(&geo),
        @constCast(&atm),
        @constCast(&obs),
        helflag,
        mag,
        azi_obj,
        azi_sun,
        azi_moon,
        alt_moon,
        &angle,
        &err_buf,
    );

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return angle;
}

test "heliacalAngle" {
    const jd: f64 = 2449090.1145833;
    const geo: [3]f64 = .{ 0, 100, 0 };
    const atm: [4]f64 = .{ 0, 0, 0, 0 };
    const obs: [6]f64 = .{ 0, 0, 1000, 30, 0, 0 };
    const mag: f64 = 0.0;
    const azi_obj: f64 = 0.0;
    const azi_sun: f64 = 0.0;
    const azi_moon: f64 = 0.0;
    const alt_moon: f64 = 0.0;

    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const angle = try heliacalAngle(
        jd,
        geo,
        atm,
        obs,
        sweph.SE_HELFLAG_HIGH_PRECISION,
        mag,
        azi_obj,
        azi_sun,
        azi_moon,
        alt_moon,
        &diags,
    );
    const expected: f64 = 2.9;
    try std.testing.expectApproxEqAbs(expected, angle, 0.1);
}

pub fn topoArcusVisionis(
    tjdut: f64,
    geo: [3]f64, // longitude, latitude, altitude
    atm: [4]f64, // pressure, temperature, humidity, etc.
    obs: [6]f64, // observer parameters
    helflag: i32,
    mag: f64,
    azi_obj: f64,
    alt_obj: f64,
    azi_sun: f64,
    azi_moon: f64,
    alt_moon: f64,
    diags: ?*Diagnostics,
) SweErr!f64 {
    var angle: f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_topo_arcus_visionis(
        tjdut,
        @constCast(&geo),
        @constCast(&atm),
        @constCast(&obs),
        helflag,
        mag,
        azi_obj,
        alt_obj,
        azi_sun,
        azi_moon,
        alt_moon,
        &angle,
        &err_buf,
    );

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return angle;
}

test "topoArcusVisionis" {
    const jd: f64 = 2449090.1145833;
    const geo: [3]f64 = .{ 0, 100, 0 };
    const atm: [4]f64 = .{ 0, 0, 0, 0 };
    const obs: [6]f64 = .{ 0, 0, 1000, 30, 0, 0 };
    const mag: f64 = 0.0;
    const azi_obj: f64 = 0.0;
    const alt_obj: f64 = 0.0;
    const azi_sun: f64 = 0.0;
    const azi_moon: f64 = 0.0;
    const alt_moon: f64 = 0.0;

    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const angle = try topoArcusVisionis(
        jd,
        geo,
        atm,
        obs,
        sweph.SE_HELFLAG_HIGH_PRECISION,
        mag,
        azi_obj,
        alt_obj,
        azi_sun,
        azi_moon,
        alt_moon,
        &diags,
    );
    const expected: f64 = 9.9e1;
    try std.testing.expectApproxEqAbs(expected, angle, 0.1);
}

pub fn version(allocator: Allocator) ![]const u8 {
    var buf: [16]u8 = undefined;
    @memset(&buf, 0);
    _ = sweph.swe_version(&buf);

    const str_len = std.mem.indexOfScalar(u8, &buf, 0) orelse buf.len;
    const copy = try allocator.alloc(u8, str_len);
    @memcpy(copy.ptr, buf[0..str_len]);

    return copy;
}

test "version" {
    const v = try version(testing.allocator);
    defer testing.allocator.free(v);
    try testing.expect(v.len > 0);

    const parts = try utils.split(testing.allocator, v, ".");
    defer parts.deinit();

    try testing.expect(parts.items.len > 0);

    var partsNum = try std.ArrayList(i32).initCapacity(testing.allocator, parts.items.len);
    defer partsNum.deinit();

    for (parts.items) |part| {
        const partNum = try std.fmt.parseInt(i32, part, 10);
        try partsNum.append(partNum);
    }

    try testing.expect(partsNum.items.len > 0);
}

pub fn getLibraryPath(allocator: Allocator) ![]const u8 {
    var buf: [sweph.AS_MAXCH]u8 = undefined;
    _ = sweph.swe_get_library_path(&buf);

    const str_len = std.mem.indexOfScalar(u8, &buf, 0) orelse buf.len;
    const copy = try allocator.alloc(u8, str_len);
    @memcpy(copy.ptr, buf[0..str_len]);

    return copy;
}

test "getLibraryPath" {
    const libPath = try getLibraryPath(testing.allocator);
    defer testing.allocator.free(libPath);
    try testing.expect(libPath.len > 0);
}

pub const CalcOut = struct {
    lon: f64,
    lat: f64,
    distance: f64,
    lon_speed: f64,
    lat_speed: f64,
    distance_speed: f64,
};

pub fn calc(jd: f64, ipl: i32, iflag: i32, diags: ?*Diagnostics) SweErr!CalcOut {
    var xxret: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_calc(jd, ipl, iflag, &xxret, &err_buf);

    if (ret_flag < 0) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xxret[0],
        .lat = xxret[1],
        .distance = xxret[2],
        .lon_speed = xxret[3],
        .lat_speed = xxret[4],
        .distance_speed = xxret[5],
    };
}

test "calc returns ephemeris" {
    setEphePath("ephe");

    const jd: f64 = 2449090.1145833;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const eph = try calc(jd, sweph.SE_SUN, sweph.SEFLG_SPEED | sweph.SEFLG_JPLEPH, &diags);
    const expected = CalcOut{
        .lon = 2.2698886768788533e1,
        .lat = -5.68713730562752e-5,
        .distance = 1.0026066384950405e0,
        .lon_speed = 9.802836638802254e-1,
        .lat_speed = 3.3018284460201747e-5,
        .distance_speed = 2.891872861964314e-4,
    };
    try std.testing.expectEqual(expected, eph);
}

test "calc with an invalid ipl returns error" {
    const jd: f64 = 2449090.1145833;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const INVALID_PLANET: i32 = -42069;
    _ = calc(jd, INVALID_PLANET, sweph.SEFLG_SPEED | sweph.SEFLG_JPLEPH, &diags) catch {
        const expected = "illegal planet number -42069.";
        try std.testing.expectEqualStrings(expected, diags.errMsg());
    };
}

pub fn calcUt(tjd_ut: f64, ipl: i32, iflag: i32, diags: ?*Diagnostics) SweErr!CalcOut {
    var xxret: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_calc_ut(tjd_ut, ipl, iflag, &xxret, &err_buf);

    if (ret_flag < @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xxret[0],
        .lat = xxret[1],
        .distance = xxret[2],
        .lon_speed = xxret[3],
        .lat_speed = xxret[4],
        .distance_speed = xxret[5],
    };
}

test "calcUt" {
    setEphePath("ephe");

    const jd: f64 = 2449090.1145833;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const eph = try calcUt(jd, sweph.SE_SUN, sweph.SEFLG_SPEED | sweph.SEFLG_JPLEPH, &diags);
    const expected = CalcOut{
        .lon = 2.2699560310264168e1,
        .lat = -5.684848332554287e-5,
        .distance = 1.0026068371922634e0,
        .lon_speed = 9.802833316902666e-1,
        .lat_speed = 3.301691113308882e-5,
        .distance_speed = 2.8918691684259125e-4,
    };
    try std.testing.expectEqual(expected, eph);
}

pub fn calcPctr(tjd: f64, ipl: i32, iplctr: i32, iflag: i32, diags: ?*Diagnostics) SweErr!CalcOut {
    var xxret: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;
    @memset(&err_buf, 0);

    const ret_flag = sweph.swe_calc_pctr(tjd, ipl, iplctr, iflag, &xxret, &err_buf);

    if (ret_flag < @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xxret[0],
        .lat = xxret[1],
        .distance = xxret[2],
        .lon_speed = xxret[3],
        .lat_speed = xxret[4],
        .distance_speed = xxret[5],
    };
}

test "calcPctr" {
    setEphePath("ephe");

    const jd: f64 = 2449090.1145833;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const eph = try calcPctr(jd, sweph.SE_EARTH, sweph.SE_SUN, sweph.SEFLG_SPEED | sweph.SEFLG_JPLEPH, &diags);
    const expected = CalcOut{
        .lon = 2.026988867841706e2,
        .lat = 5.687222955612085e-5,
        .distance = 1.0026049617855035e0,
        .lon_speed = 9.802839852538352e-1,
        .lat_speed = -3.303987678735e-5,
        .distance_speed = 2.891912115442801e-4,
    };
    try std.testing.expectEqual(expected, eph);
}

pub fn solcross(x2cross: f64, jd_et: f64, flag: i32, diags: ?*Diagnostics) !f64 {
    var err_buf: [256:0]u8 = undefined;

    const jd = sweph.swe_solcross(x2cross, jd_et, flag, &err_buf);

    // if jd < jd_et, this is an error.
    // See the implementation of `swe_solcross` for more info in sweph.c
    if (jd < jd_et) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "solcross returns a julian day" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69.420;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const jd = try solcross(lon, start_jd, sweph.SEFLG_TRUEPOS, &diags);

    try testing.expect(jd > start_jd);
}

test "solcross successfully fails" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 700;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    _ = solcross(lon, start_jd, -69, &diags) catch |err| {
        try testing.expect(err == SweErr.CalcFailure);
    };
}

pub fn solcrossUt(x2cross: f64, jd_ut: f64, flag: i32, diags: ?*Diagnostics) !f64 {
    var err_buf: [256:0]u8 = undefined;

    const jd = sweph.swe_solcross_ut(x2cross, jd_ut, flag, &err_buf);

    // if jd < jd_et, this is an error.
    // See the implementation of `swe_solcross_ut` for more info in sweph.c
    if (jd < jd_ut) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "solcrossUt" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69.420;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const jd = try solcrossUt(lon, start_jd, sweph.SEFLG_TRUEPOS, &diags);

    try testing.expect(jd > start_jd);
}

pub fn mooncross(x2cross: f64, jd_et: f64, flag: i32, diags: ?*Diagnostics) !f64 {
    var err_buf: [256:0]u8 = undefined;

    const jd = sweph.swe_mooncross(x2cross, jd_et, flag, &err_buf);

    // if jd < jd_et, this is an error.
    // See the implementation of `swe_solcross` for more info in sweph.c
    if (jd < jd_et) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "mooncross" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69.420;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const jd = try mooncross(lon, start_jd, sweph.SEFLG_TRUEPOS, &diags);

    try testing.expect(jd > start_jd);
}

pub fn mooncrossUt(x2cross: f64, jd_ut: f64, flag: i32, diags: ?*Diagnostics) !f64 {
    var err_buf: [256:0]u8 = undefined;

    const jd = sweph.swe_mooncross(x2cross, jd_ut, flag, &err_buf);

    // if jd < jd_et, this is an error.
    // See the implementation of `swe_solcross` for more info in sweph.c
    if (jd < jd_ut) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "mooncrossUt" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69.420;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const jd = try mooncross(lon, start_jd, sweph.SEFLG_TRUEPOS, &diags);

    try testing.expect(jd > start_jd);
}

pub fn mooncrossNode(
    jd_et: f64,
    flag: i32,
    lon: f64,
    lat: f64,
    diags: ?*Diagnostics,
) !f64 {
    var err_buf: [256:0]u8 = undefined;

    const jd = sweph.swe_mooncross_node(
        jd_et,
        flag,
        @constCast(&lon),
        @constCast(&lat),
        &err_buf,
    );

    // if jd < jd_et, this is an error.
    // See the implementation of `swe_mooncross_node` for more info in sweph.c
    if (jd < jd_et) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "mooncrossNode" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69;
    const lat: f64 = 420;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const jd = try mooncrossNode(
        start_jd,
        sweph.SEFLG_TRUEPOS,
        lon,
        lat,
        &diags,
    );

    try testing.expect(jd > start_jd);
}

pub fn mooncrossNodeUt(
    jd_ut: f64,
    flag: i32,
    lon: f64,
    lat: f64,
    diags: ?*Diagnostics,
) !f64 {
    var err_buf: [256:0]u8 = undefined;

    const jd = sweph.swe_mooncross_node_ut(
        jd_ut,
        flag,
        @constCast(&lon),
        @constCast(&lat),
        &err_buf,
    );

    // if jd < jd_et, this is an error.
    // See the implementation of `swe_mooncross_node_ut` for more info in sweph.c
    if (jd < jd_ut) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "mooncrossNodeUt" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69;
    const lat: f64 = 420;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const jd = try mooncrossNodeUt(
        start_jd,
        sweph.SEFLG_TRUEPOS,
        lon,
        lat,
        &diags,
    );

    try testing.expect(jd > start_jd);
}

pub fn helioCross(ipl: i32, x2cross: f64, jd_et: f64, iflag: i32, dir: i32, diags: ?*Diagnostics) !f64 {
    var jd: f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_helio_cross(
        ipl,
        x2cross,
        jd_et,
        iflag,
        dir,
        @constCast(&jd),
        &err_buf,
    );

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "helioCross" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69.420;
    const dir: i32 = 1;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();

    const jd = try helioCross(sweph.SE_MERCURY, lon, start_jd, sweph.SEFLG_TRUEPOS, dir, &diags);

    try testing.expect(jd > start_jd);
}

pub fn helioCrossUt(ipl: i32, x2cross: f64, jd_ut: f64, iflag: i32, dir: i32, diags: ?*Diagnostics) !f64 {
    var jd: f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_helio_cross_ut(
        ipl,
        x2cross,
        jd_ut,
        iflag,
        dir,
        @constCast(&jd),
        &err_buf,
    );

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return jd;
}

test "helioCrossUt" {
    const start_jd: f64 = 2449090.1145833;
    const lon: f64 = 69.420;
    const dir: i32 = 1;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();

    const jd = try helioCrossUt(sweph.SE_MERCURY, lon, start_jd, sweph.SEFLG_TRUEPOS, dir, &diags);

    try testing.expect(jd > start_jd);
}

pub fn fixstar(
    star: []const u8,
    tjd: f64,
    iflag: i32,
    diags: ?*Diagnostics,
) !CalcOut {
    var xx: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;
    var star_buf = utils.strSliceToFixed(star, 41);

    const ret_flag = sweph.swe_fixstar(&star_buf, tjd, iflag, &xx, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xx[0],
        .lat = xx[1],
        .distance = xx[2],
        .lon_speed = xx[3],
        .lat_speed = xx[4],
        .distance_speed = xx[5],
    };
}

test "fixstar" {
    const jd: f64 = 2449090.1145833;
    _ = try fixstar("Bunda", jd, sweph.SEFLG_JPLEPH | sweph.SEFLG_SPEED, undefined);
}

pub fn fixstarUt(
    star: []const u8,
    tjd_ut: f64,
    iflag: i32,
    diags: ?*Diagnostics,
) !CalcOut {
    var xx: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;
    var star_buf = utils.strSliceToFixed(star, 41);

    const ret_flag = sweph.swe_fixstar_ut(&star_buf, tjd_ut, iflag, &xx, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xx[0],
        .lat = xx[1],
        .distance = xx[2],
        .lon_speed = xx[3],
        .lat_speed = xx[4],
        .distance_speed = xx[5],
    };
}

test "fixstarUt" {
    const jd: f64 = 2449090.1145833;
    _ = try fixstarUt("Bunda", jd, sweph.SEFLG_JPLEPH | sweph.SEFLG_SPEED, undefined);
}

pub fn fixstarMag(star: []const u8, diags: ?*Diagnostics) !f64 {
    var mag: f64 = undefined;
    var err_buf: [256]u8 = undefined;
    var star_buf = utils.strSliceToFixed(star, 41);

    const ret_flag = sweph.swe_fixstar_mag(&star_buf, &mag, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return mag;
}

test "fixstarMag" {
    _ = try fixstarMag("Bunda", undefined);
}

pub fn fixstar2(
    star: []const u8,
    tjd: f64,
    iflag: i32,
    diags: ?*Diagnostics,
) !CalcOut {
    var xx: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;
    var star_buf = utils.strSliceToFixed(star, 41);

    const ret_flag = sweph.swe_fixstar2(&star_buf, tjd, iflag, &xx, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xx[0],
        .lat = xx[1],
        .distance = xx[2],
        .lon_speed = xx[3],
        .lat_speed = xx[4],
        .distance_speed = xx[5],
    };
}

test "fixstar2" {
    const jd: f64 = 2449090.1145833;
    _ = try fixstar2("Bunda", jd, sweph.SEFLG_JPLEPH | sweph.SEFLG_SPEED, undefined);
}

pub fn fixstar2Ut(
    star: []const u8,
    tjd_ut: f64,
    iflag: i32,
    diags: ?*Diagnostics,
) !CalcOut {
    var xx: [6]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;
    var star_buf = utils.strSliceToFixed(star, 41);

    const ret_flag = sweph.swe_fixstar2_ut(&star_buf, tjd_ut, iflag, &xx, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return CalcOut{
        .lon = xx[0],
        .lat = xx[1],
        .distance = xx[2],
        .lon_speed = xx[3],
        .lat_speed = xx[4],
        .distance_speed = xx[5],
    };
}

test "fixstar2Ut" {
    const jd: f64 = 2449090.1145833;
    _ = try fixstar2Ut("Bunda", jd, sweph.SEFLG_JPLEPH | sweph.SEFLG_SPEED, undefined);
}

pub fn fixstar2Mag(star: []const u8, diags: ?*Diagnostics) !f64 {
    var mag: f64 = undefined;
    var err_buf: [256]u8 = undefined;
    var star_buf = utils.strSliceToFixed(star, 41);

    const ret_flag = sweph.swe_fixstar2_mag(&star_buf, &mag, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return mag;
}

test "fixstar2Mag" {
    _ = try fixstar2Mag("Bunda", undefined);
}

pub fn close() void {
    sweph.swe_close();
}

pub fn setEphePath(path: [*c]const u8) void {
    sweph.swe_set_ephe_path(path);
}

pub fn setJplFile(fname: []const u8) void {
    sweph.swe_set_jpl_file(fname);
}

test "setJplFile" {
    sweph.swe_set_jpl_file("path/to/file");
}

pub fn getPlanetName(allocator: Allocator, ipl: i32) ![]const u8 {
    var buf: [256]u8 = undefined;
    @memset(&buf, 0);

    _ = sweph.swe_get_planet_name(ipl, &buf);

    const notFoundIdx = std.mem.indexOf(u8, &buf, "not found");
    if (notFoundIdx != null) {
        return SweErr.NotFound;
    }

    const str_len = std.mem.indexOfScalar(u8, &buf, 0) orelse buf.len;
    const pl_name = try allocator.alloc(u8, str_len);
    @memcpy(pl_name.ptr, buf[0..str_len]);

    return pl_name;
}

test "getPlanetName finds name for existing planet" {
    const pl_name = try getPlanetName(testing.allocator, sweph.SE_EARTH);
    defer testing.allocator.free(pl_name);
    try std.testing.expectEqualStrings("Earth", pl_name);
}

test "getPlanetName returns an error if planet name is not found" {
    _ = getPlanetName(testing.allocator, std.math.maxInt(i32)) catch |err| {
        try std.testing.expect(err == SweErr.NotFound);
    };
}

pub fn setTopo(geolon: f64, geolat: f64, geoalt: f64) void {
    sweph.swe_set_topo(geolon, geolat, geoalt);
}

test "setTopo" {
    setTopo(69, 4.20, 80085);
}

pub fn setSidMode(sid_mode: i32, t0: f64, ayan_t0: f64) void {
    sweph.swe_set_sid_mode(sid_mode, t0, ayan_t0);
}

test "setSidMode" {
    setSidMode(sweph.SE_SIDM_ARYABHATA, 0, 0);
}

pub fn getAyanamsaEx(tjd_et: f64, iflag: i32, diags: ?*Diagnostics) !f64 {
    var err_buf: [256:0]u8 = undefined;
    var aya: f64 = undefined;

    const ret_flag = sweph.swe_get_ayanamsa_ex(tjd_et, iflag, &aya, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return aya;
}

test "getAyanamsaEx" {
    //
    const jd: f64 = 2449090.1145833;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const aya = try getAyanamsaEx(jd, sweph.SEFLG_JPLEPH, &diags);

    try testing.expect(aya > 0);
}

pub fn getAyanamsaExUt(tjd_ut: f64, iflag: i32, diags: ?*Diagnostics) !f64 {
    var err_buf: [256:0]u8 = undefined;
    var aya: f64 = undefined;

    const ret_flag = sweph.swe_get_ayanamsa_ex_ut(tjd_ut, iflag, &aya, &err_buf);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.CalcFailure;
    }

    return aya;
}

test "getAyanamsaExUt" {
    //
    const jd: f64 = 2449090.1145833;
    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const aya = try getAyanamsaExUt(jd, sweph.SEFLG_JPLEPH, &diags);

    try testing.expect(aya > 0);
}

pub fn getAyanamsa(tjd_et: f64) f64 {
    return sweph.swe_get_ayanamsa(tjd_et);
}

test "getAyanamsa" {
    const jd: f64 = 2449090.1145833;
    const aya = getAyanamsa(jd);

    try testing.expect(aya > 0);
}

pub fn getAyanamsaUt(tjd_ut: f64) f64 {
    return sweph.swe_get_ayanamsa_ut(tjd_ut);
}

test "getAyanamsaUt" {
    const jd: f64 = 2449090.1145833;
    const aya = getAyanamsaUt(jd);

    try testing.expect(aya > 0);
}

pub fn getAyanamsaName(isidmode: i32) []const u8 {
    const aya_name = sweph.swe_get_ayanamsa_name(isidmode);

    const len = utils.strlen(aya_name);

    return aya_name[0..len];
}

test "getAyanamsaName" {
    const name = getAyanamsaName(sweph.SE_SIDM_LAHIRI);
    try testing.expectEqualStrings(name, "Lahiri");
}

const GetCurrentFileDataOut = struct {
    filepath: []const u8,
    file_start_jd: f64,
    file_end_jd: f64,
    jpl_ephemeris_num: i32,
};

pub fn getCurrentFileData(ifno: i32) !GetCurrentFileDataOut {
    var tfstart: f64 = undefined;
    var tfend: f64 = undefined;
    var denum: i32 = undefined;

    const filepath = sweph.swe_get_current_file_data(ifno, &tfstart, &tfend, &denum);
    if (filepath == null) {
        return SweErr.NotFound;
    }

    const len = utils.strlen(filepath);

    return GetCurrentFileDataOut{
        .filepath = filepath[0..len],
        .file_start_jd = tfstart,
        .file_end_jd = tfend,
        .jpl_ephemeris_num = denum,
    };
}

test "getCurrentFileData" {
    const res = try getCurrentFileData(0);
    try testing.expectEqualStrings("ephe/file", res.filepath);

    _ = getCurrentFileData(5) catch |err| {
        try testing.expect(err == SweErr.NotFound);
    };
}

pub fn dateConversion(
    y: i32,
    m: i32,
    d: i32,
    uttime: f64,
    c: CalendarFlag,
) !f64 {
    var jd: f64 = undefined;

    const calendar_byte: u8 = @intFromEnum(c);
    const ret_flag = sweph.swe_date_conversion(y, m, d, uttime, calendar_byte, &jd);

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        return SweErr.InvalidDate;
    }

    return jd;
}

test "dateConversion" {
    const jd = try dateConversion(1970, 1, 1, 0, .g);

    const expected: f64 = 2440587.5;
    try testing.expectEqual(expected, jd);

    _ = dateConversion(1970, 1, 32, 0, .g) catch |err| {
        try testing.expect(err == SweErr.InvalidDate);
        return;
    };

    try testing.expect(false);
}

pub fn julday(year: i32, month: i32, day: i32, hour: f64, gregflag: i32) f64 {
    return sweph.swe_julday(year, month, day, hour, gregflag);
}

test "julday" {
    var jd: f64 = undefined;

    jd = julday(1970, 1, -1, 0, sweph.SE_GREG_CAL);
    const december_30 = 2440585.5;
    try testing.expectEqual(december_30, jd);

    jd = julday(1970, 1, 0, 0, sweph.SE_GREG_CAL);
    const december_31 = 2440586.5;
    try testing.expectEqual(december_31, jd);

    jd = julday(1970, 1, 1, 0, sweph.SE_GREG_CAL);
    const january_1 = 2440587.5;
    try testing.expectEqual(january_1, jd);

    jd = julday(1970, 1, 31, 0, sweph.SE_GREG_CAL);
    const january_31 = 2440617.5;
    try testing.expectEqual(january_31, jd);

    jd = julday(1970, 1, 32, 0, sweph.SE_GREG_CAL);
    const february_1 = 2440618.5;
    try testing.expectEqual(february_1, jd);
}

const RevJulOut = struct {
    year: i32,
    month: i32,
    day: i32,
    hour: f64,
};

pub fn revjul(jd: f64, gregflag: i32) RevJulOut {
    var year: i32 = undefined;
    var month: i32 = undefined;
    var day: i32 = undefined;
    var hour: f64 = undefined;

    sweph.swe_revjul(jd, gregflag, &year, &month, &day, &hour);

    return .{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
    };
}

test "revjul" {
    const january_1_1970 = 2440587.5;
    const date = revjul(january_1_1970, sweph.SE_GREG_CAL);

    const expected = RevJulOut{
        .year = 1970,
        .month = 1,
        .day = 1,
        .hour = 0.0,
    };

    try testing.expectEqual(expected, date);
}

const UtcToJdOut = struct {
    jd_et: f64,
    jd_ut1: f64,
};

pub fn utcToJd(
    iyear: i32,
    imonth: i32,
    iday: i32,
    ihour: i32,
    imin: i32,
    dsec: f64,
    gregflag: i32,
    diags: ?*Diagnostics,
) !UtcToJdOut {
    var jds: [2]f64 = undefined;
    var err_buf: [256:0]u8 = undefined;

    const ret_flag = sweph.swe_utc_to_jd(
        iyear,
        imonth,
        iday,
        ihour,
        imin,
        dsec,
        gregflag,
        &jds,
        &err_buf,
    );

    if (ret_flag == @intFromEnum(SweRetFlag.ERR)) {
        if (diags) |d| {
            try d.setErrMsg(&err_buf);
        }
        return SweErr.InvalidDate;
    }

    return .{
        .jd_et = jds[0],
        .jd_ut1 = jds[1],
    };
}

test "utcToJd" {
    const jds = try utcToJd(1970, 1, 1, 0, 0, 0, sweph.SE_GREG_CAL, undefined);
    const expected_jds: UtcToJdOut = .{
        .jd_et = 2440587.500465062,
        .jd_ut1 = 2440587.5,
    };
    try testing.expectEqual(expected_jds, jds);

    var diags = Diagnostics.init(testing.allocator);
    defer diags.deinit();
    const year = 1970;
    const month = 1;
    const invalid_day = -1;
    _ = utcToJd(year, month, invalid_day, 0, 0, 0, 2, &diags) catch |err| {
        try testing.expect(err == SweErr.InvalidDate);

        const expected_err_msg = try std.fmt.allocPrint(
            testing.allocator,
            "invalid date: year = {d}, month = {d}, day = {d}",
            .{ year, month, invalid_day },
        );
        defer testing.allocator.free(expected_err_msg);
        try testing.expectEqualStrings(expected_err_msg, diags.errMsg());
    };
}

const UTC = struct {
    year: i32,
    month: i32,
    day: i32,
    hour: i32,
    min: i32,
    sec: f64,
};

pub fn jdetToUtc(tjd_et: f64, gregflag: i32) UTC {
    var year: i32 = undefined;
    var month: i32 = undefined;
    var day: i32 = undefined;
    var hour: i32 = undefined;
    var min: i32 = undefined;
    var sec: f64 = undefined;

    sweph.swe_jdet_to_utc(
        tjd_et,
        gregflag,
        &year,
        &month,
        &day,
        &hour,
        &min,
        &sec,
    );

    return .{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .min = min,
        .sec = sec,
    };
}

test "jdetToUtc" {
    const jds = try utcToJd(1970, 1, 1, 0, 0, 0, sweph.SE_GREG_CAL, undefined);
    const utc = jdetToUtc(jds.jd_et, sweph.SE_GREG_CAL);

    try testing.expectEqual(utc.year, 1970);
    try testing.expectEqual(utc.month, 1);
    try testing.expectEqual(utc.day, 1);
    try testing.expectEqual(utc.hour, 0);
    try testing.expectEqual(utc.min, 0);
    try testing.expectEqual(utc.sec, 0);
}

pub fn jdut1ToUtc(tjd_ut: f64, gregflag: i32) UTC {
    var year: i32 = undefined;
    var month: i32 = undefined;
    var day: i32 = undefined;
    var hour: i32 = undefined;
    var min: i32 = undefined;
    var sec: f64 = undefined;

    sweph.swe_jdut1_to_utc(
        tjd_ut,
        gregflag,
        &year,
        &month,
        &day,
        &hour,
        &min,
        &sec,
    );

    return .{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .min = min,
        .sec = sec,
    };
}

test "jdut1ToUtc" {
    const jds = try utcToJd(1970, 1, 1, 0, 0, 0, sweph.SE_GREG_CAL, undefined);
    const utc = jdut1ToUtc(jds.jd_ut1, sweph.SE_GREG_CAL);

    try testing.expectEqual(utc.year, 1970);
    try testing.expectEqual(utc.month, 1);
    try testing.expectEqual(utc.day, 1);
    try testing.expectEqual(utc.hour, 0);
    try testing.expectEqual(utc.min, 0);
    try testing.expectEqual(utc.sec, 0);
}

pub const defs = struct {
    pub const SE_AUNIT_TO_KM = sweph.SE_AUNIT_TO_KM;
    pub const SE_AUNIT_TO_LIGHTYEAR = sweph.SE_AUNIT_TO_LIGHTYEAR;
    pub const SE_AUNIT_TO_PARSEC = sweph.SE_AUNIT_TO_PARSEC;

    pub const SE_JUL_CAL = sweph.SE_JUL_CAL;
    pub const SE_GREG_CAL = sweph.SE_GREG_CAL;

    pub const SE_ECL_NUT = sweph.SE_ECL_NUT;

    pub const SE_SUN = sweph.SE_SUN;
    pub const SE_MOON = sweph.SE_MOON;
    pub const SE_MERCURY = sweph.SE_MERCURY;
    pub const SE_VENUS = sweph.SE_VENUS;
    pub const SE_MARS = sweph.SE_MARS;
    pub const SE_JUPITER = sweph.SE_JUPITER;
    pub const SE_SATURN = sweph.SE_SATURN;
    pub const SE_URANUS = sweph.SE_URANUS;
    pub const SE_NEPTUNE = sweph.SE_NEPTUNE;
    pub const SE_PLUTO = sweph.SE_PLUTO;
    pub const SE_MEAN_NODE = sweph.SE_MEAN_NODE;
    pub const SE_TRUE_NODE = sweph.SE_TRUE_NODE;
    pub const SE_MEAN_APOG = sweph.SE_MEAN_APOG;
    pub const SE_OSCU_APOG = sweph.SE_OSCU_APOG;
    pub const SE_EARTH = sweph.SE_EARTH;
    pub const SE_CHIRON = sweph.SE_CHIRON;
    pub const SE_PHOLUS = sweph.SE_PHOLUS;
    pub const SE_CERES = sweph.SE_CERES;
    pub const SE_PALLAS = sweph.SE_PALLAS;
    pub const SE_JUNO = sweph.SE_JUNO;
    pub const SE_VESTA = sweph.SE_VESTA;
    pub const SE_INTP_APOG = sweph.SE_INTP_APOG;
    pub const SE_INTP_PERG = sweph.SE_INTP_PERG;

    pub const SE_NPLANETS = sweph.SE_NPLANETS;

    pub const SE_PLMOON_OFFSET = sweph.SE_PLMOON_OFFSET;
    pub const SE_AST_OFFSET = sweph.SE_AST_OFFSET;
    pub const SE_VARUNA = sweph.SE_VARUNA;

    pub const SE_FICT_OFFSET = sweph.SE_FICT_OFFSET;
    pub const SE_FICT_OFFSET_1 = sweph.SE_FICT_OFFSET_1;
    pub const SE_FICT_MAX = sweph.SE_FICT_MAX;
    pub const SE_NFICT_ELEM = sweph.SE_NFICT_ELEM;

    pub const SE_COMET_OFFSET = sweph.SE_COMET_OFFSET;

    pub const SE_NALL_NAT_POINTS = sweph.SE_NALL_NAT_POINTS;

    pub const SE_CUPIDO = sweph.SE_CUPIDO;
    pub const SE_HADES = sweph.SE_HADES;
    pub const SE_ZEUS = sweph.SE_ZEUS;
    pub const SE_KRONOS = sweph.SE_KRONOS;
    pub const SE_APOLLON = sweph.SE_APOLLON;
    pub const SE_ADMETOS = sweph.SE_ADMETOS;
    pub const SE_VULKANUS = sweph.SE_VULKANUS;
    pub const SE_POSEIDON = sweph.SE_POSEIDON;
    pub const SE_ISIS = sweph.SE_ISIS;
    pub const SE_NIBIRU = sweph.SE_NIBIRU;
    pub const SE_HARRINGTON = sweph.SE_HARRINGTON;
    pub const SE_NEPTUNE_LEVERRIER = sweph.SE_NEPTUNE_LEVERRIER;
    pub const SE_NEPTUNE_ADAMS = sweph.SE_NEPTUNE_ADAMS;
    pub const SE_PLUTO_LOWELL = sweph.SE_PLUTO_LOWELL;
    pub const SE_PLUTO_PICKERING = sweph.SE_PLUTO_PICKERING;
    pub const SE_VULCAN = sweph.SE_VULCAN;
    pub const SE_WHITE_MOON = sweph.SE_WHITE_MOON;
    pub const SE_PROSERPINA = sweph.SE_PROSERPINA;
    pub const SE_WALDEMATH = sweph.SE_WALDEMATH;

    pub const SE_FIXSTAR = sweph.SE_FIXSTAR;

    pub const SE_ASC = sweph.SE_ASC;
    pub const SE_MC = sweph.SE_MC;
    pub const SE_ARMC = sweph.SE_ARMC;
    pub const SE_VERTEX = sweph.SE_VERTEX;
    pub const SE_EQUASC = sweph.SE_EQUASC;
    pub const SE_COASC1 = sweph.SE_COASC1;
    pub const SE_COASC2 = sweph.SE_COASC2;
    pub const SE_POLASC = sweph.SE_POLASC;
    pub const SE_NASCMC = sweph.SE_NASCMC;

    pub const SEFLG_JPLEPH = sweph.SEFLG_JPLEPH;
    pub const SEFLG_SWIEPH = sweph.SEFLG_SWIEPH;
    pub const SEFLG_MOSEPH = sweph.SEFLG_MOSEPH;

    pub const SEFLG_HELCTR = sweph.SEFLG_HELCTR;
    pub const SEFLG_TRUEPOS = sweph.SEFLG_TRUEPOS;
    pub const SEFLG_J2000 = sweph.SEFLG_J2000;
    pub const SEFLG_NONUT = sweph.SEFLG_NONUT;
    pub const SEFLG_SPEED3 = sweph.SEFLG_SPEED3;
    pub const SEFLG_SPEED = sweph.SEFLG_SPEED;
    pub const SEFLG_NOGDEFL = sweph.SEFLG_NOGDEFL;
    pub const SEFLG_NOABERR = sweph.SEFLG_NOABERR;
    pub const SEFLG_ASTROMETRIC = sweph.SEFLG_ASTROMETRIC;
    pub const SEFLG_EQUATORIAL = sweph.SEFLG_EQUATORIAL;
    pub const SEFLG_XYZ = sweph.SEFLG_XYZ;
    pub const SEFLG_RADIANS = sweph.SEFLG_RADIANS;
    pub const SEFLG_BARYCTR = sweph.SEFLG_BARYCTR;
    pub const SEFLG_TOPOCTR = sweph.SEFLG_TOPOCTR;
    pub const SEFLG_ORBEL_AA = sweph.SEFLG_ORBEL_AA;
    pub const SEFLG_TROPICAL = sweph.SEFLG_TROPICAL;
    pub const SEFLG_SIDEREAL = sweph.SEFLG_SIDEREAL;
    pub const SEFLG_ICRS = sweph.SEFLG_ICRS;
    pub const SEFLG_DPSIDEPS_1980 = sweph.SEFLG_DPSIDEPS_1980;
    pub const SEFLG_JPLHOR = sweph.SEFLG_JPLHOR;
    pub const SEFLG_JPLHOR_APPROX = sweph.SEFLG_JPLHOR_APPROX;
    pub const SEFLG_CENTER_BODY = sweph.SEFLG_CENTER_BODY;
    pub const SEFLG_TEST_PLMOON = sweph.SEFLG_TEST_PLMOON;

    pub const SE_SIDBITS = sweph.SE_SIDBITS;
    pub const SE_SIDBIT_ECL_T0 = sweph.SE_SIDBIT_ECL_T0;
    pub const SE_SIDBIT_SSY_PLANE = sweph.SE_SIDBIT_SSY_PLANE;
    pub const SE_SIDBIT_USER_UT = sweph.SE_SIDBIT_USER_UT;
    pub const SE_SIDBIT_ECL_DATE = sweph.SE_SIDBIT_ECL_DATE;

    pub const SE_SIDBIT_NO_PREC_OFFSET = sweph.SE_SIDBIT_NO_PREC_OFFSET;
    pub const SE_SIDBIT_PREC_ORIG = sweph.SE_SIDBIT_PREC_ORIG;

    pub const SE_SIDM_FAGAN_BRADLEY = sweph.SE_SIDM_FAGAN_BRADLEY;
    pub const SE_SIDM_LAHIRI = sweph.SE_SIDM_LAHIRI;
    pub const SE_SIDM_DELUCE = sweph.SE_SIDM_DELUCE;
    pub const SE_SIDM_RAMAN = sweph.SE_SIDM_RAMAN;
    pub const SE_SIDM_USHASHASHI = sweph.SE_SIDM_USHASHASHI;
    pub const SE_SIDM_KRISHNAMURTI = sweph.SE_SIDM_KRISHNAMURTI;
    pub const SE_SIDM_DJWHAL_KHUL = sweph.SE_SIDM_DJWHAL_KHUL;
    pub const SE_SIDM_YUKTESHWAR = sweph.SE_SIDM_YUKTESHWAR;
    pub const SE_SIDM_JN_BHASIN = sweph.SE_SIDM_JN_BHASIN;
    pub const SE_SIDM_BABYL_KUGLER1 = sweph.SE_SIDM_BABYL_KUGLER1;
    pub const SE_SIDM_BABYL_KUGLER2 = sweph.SE_SIDM_BABYL_KUGLER2;
    pub const SE_SIDM_BABYL_KUGLER3 = sweph.SE_SIDM_BABYL_KUGLER3;
    pub const SE_SIDM_BABYL_HUBER = sweph.SE_SIDM_BABYL_HUBER;
    pub const SE_SIDM_BABYL_ETPSC = sweph.SE_SIDM_BABYL_ETPSC;
    pub const SE_SIDM_ALDEBARAN_15TAU = sweph.SE_SIDM_ALDEBARAN_15TAU;
    pub const SE_SIDM_HIPPARCHOS = sweph.SE_SIDM_HIPPARCHOS;
    pub const SE_SIDM_SASSANIAN = sweph.SE_SIDM_SASSANIAN;
    pub const SE_SIDM_GALCENT_0SAG = sweph.SE_SIDM_GALCENT_0SAG;
    pub const SE_SIDM_J2000 = sweph.SE_SIDM_J2000;
    pub const SE_SIDM_J1900 = sweph.SE_SIDM_J1900;
    pub const SE_SIDM_B1950 = sweph.SE_SIDM_B1950;
    pub const SE_SIDM_SURYASIDDHANTA = sweph.SE_SIDM_SURYASIDDHANTA;
    pub const SE_SIDM_SURYASIDDHANTA_MSUN = sweph.SE_SIDM_SURYASIDDHANTA_MSUN;
    pub const SE_SIDM_ARYABHATA = sweph.SE_SIDM_ARYABHATA;
    pub const SE_SIDM_ARYABHATA_MSUN = sweph.SE_SIDM_ARYABHATA_MSUN;
    pub const SE_SIDM_SS_REVATI = sweph.SE_SIDM_SS_REVATI;
    pub const SE_SIDM_SS_CITRA = sweph.SE_SIDM_SS_CITRA;
    pub const SE_SIDM_TRUE_CITRA = sweph.SE_SIDM_TRUE_CITRA;
    pub const SE_SIDM_TRUE_REVATI = sweph.SE_SIDM_TRUE_REVATI;
    pub const SE_SIDM_TRUE_PUSHYA = sweph.SE_SIDM_TRUE_PUSHYA;
    pub const SE_SIDM_GALCENT_RGILBRAND = sweph.SE_SIDM_GALCENT_RGILBRAND;
    pub const SE_SIDM_GALEQU_IAU1958 = sweph.SE_SIDM_GALEQU_IAU1958;
    pub const SE_SIDM_GALEQU_TRUE = sweph.SE_SIDM_GALEQU_TRUE;
    pub const SE_SIDM_GALEQU_MULA = sweph.SE_SIDM_GALEQU_MULA;
    pub const SE_SIDM_GALALIGN_MARDYKS = sweph.SE_SIDM_GALALIGN_MARDYKS;
    pub const SE_SIDM_TRUE_MULA = sweph.SE_SIDM_TRUE_MULA;
    pub const SE_SIDM_GALCENT_MULA_WILHELM = sweph.SE_SIDM_GALCENT_MULA_WILHELM;
    pub const SE_SIDM_ARYABHATA_522 = sweph.SE_SIDM_ARYABHATA_522;
    pub const SE_SIDM_BABYL_BRITTON = sweph.SE_SIDM_BABYL_BRITTON;
    pub const SE_SIDM_TRUE_SHEORAN = sweph.SE_SIDM_TRUE_SHEORAN;
    pub const SE_SIDM_GALCENT_COCHRANE = sweph.SE_SIDM_GALCENT_COCHRANE;
    pub const SE_SIDM_GALEQU_FIORENZA = sweph.SE_SIDM_GALEQU_FIORENZA;
    pub const SE_SIDM_VALENS_MOON = sweph.SE_SIDM_VALENS_MOON;
    pub const SE_SIDM_LAHIRI_1940 = sweph.SE_SIDM_LAHIRI_1940;
    pub const SE_SIDM_LAHIRI_VP285 = sweph.SE_SIDM_LAHIRI_VP285;
    pub const SE_SIDM_KRISHNAMURTI_VP291 = sweph.SE_SIDM_KRISHNAMURTI_VP291;
    pub const SE_SIDM_LAHIRI_ICRC = sweph.SE_SIDM_LAHIRI_ICRC;
    //pub const SE_SIDM_MANJULA = sweph.SE_SIDM_MANJULA;
    pub const SE_SIDM_USER = sweph.SE_SIDM_USER;

    pub const SE_NSIDM_PREDEF = sweph.SE_NSIDM_PREDEF;

    pub const SE_NODBIT_MEAN = sweph.SE_NODBIT_MEAN;
    pub const SE_NODBIT_OSCU = sweph.SE_NODBIT_OSCU;
    pub const SE_NODBIT_OSCU_BAR = sweph.SE_NODBIT_OSCU_BAR;
    pub const SE_NODBIT_FOPOINT = sweph.SE_NODBIT_FOPOINT;

    pub const SEFLG_DEFAULTEPH = sweph.SEFLG_DEFAULTEPH;

    pub const SE_MAX_STNAME = sweph.SE_MAX_STNAME;

    pub const SE_ECL_CENTRAL = sweph.SE_ECL_CENTRAL;
    pub const SE_ECL_NONCENTRAL = sweph.SE_ECL_NONCENTRAL;
    pub const SE_ECL_TOTAL = sweph.SE_ECL_TOTAL;
    pub const SE_ECL_ANNULAR = sweph.SE_ECL_ANNULAR;
    pub const SE_ECL_PARTIAL = sweph.SE_ECL_PARTIAL;
    pub const SE_ECL_ANNULAR_TOTAL = sweph.SE_ECL_ANNULAR_TOTAL;
    pub const SE_ECL_HYBRID = sweph.SE_ECL_HYBRID;
    pub const SE_ECL_PENUMBRAL = sweph.SE_ECL_PENUMBRAL;
    pub const SE_ECL_ALLTYPES_SOLAR = sweph.SE_ECL_ALLTYPES_SOLAR;
    pub const SE_ECL_ALLTYPES_LUNAR = sweph.SE_ECL_ALLTYPES_LUNAR;
    pub const SE_ECL_VISIBLE = sweph.SE_ECL_VISIBLE;
    pub const SE_ECL_MAX_VISIBLE = sweph.SE_ECL_MAX_VISIBLE;
    pub const SE_ECL_1ST_VISIBLE = sweph.SE_ECL_1ST_VISIBLE;
    pub const SE_ECL_PARTBEG_VISIBLE = sweph.SE_ECL_PARTBEG_VISIBLE;
    pub const SE_ECL_2ND_VISIBLE = sweph.SE_ECL_2ND_VISIBLE;
    pub const SE_ECL_TOTBEG_VISIBLE = sweph.SE_ECL_TOTBEG_VISIBLE;
    pub const SE_ECL_3RD_VISIBLE = sweph.SE_ECL_3RD_VISIBLE;
    pub const SE_ECL_TOTEND_VISIBLE = sweph.SE_ECL_TOTEND_VISIBLE;
    pub const SE_ECL_4TH_VISIBLE = sweph.SE_ECL_4TH_VISIBLE;
    pub const SE_ECL_PARTEND_VISIBLE = sweph.SE_ECL_PARTEND_VISIBLE;
    pub const SE_ECL_PENUMBBEG_VISIBLE = sweph.SE_ECL_PENUMBBEG_VISIBLE;
    pub const SE_ECL_PENUMBEND_VISIBLE = sweph.SE_ECL_PENUMBEND_VISIBLE;
    pub const SE_ECL_OCC_BEG_DAYLIGHT = sweph.SE_ECL_OCC_BEG_DAYLIGHT;
    pub const SE_ECL_OCC_END_DAYLIGHT = sweph.SE_ECL_OCC_END_DAYLIGHT;
    pub const SE_ECL_ONE_TRY = sweph.SE_ECL_ONE_TRY;
    pub const SE_CALC_RISE = sweph.SE_CALC_RISE;
    pub const SE_CALC_SET = sweph.SE_CALC_SET;
    pub const SE_CALC_MTRANSIT = sweph.SE_CALC_MTRANSIT;
    pub const SE_CALC_ITRANSIT = sweph.SE_CALC_ITRANSIT;
    pub const SE_BIT_DISC_CENTER = sweph.SE_BIT_DISC_CENTER;
    pub const SE_BIT_DISC_BOTTOM = sweph.SE_BIT_DISC_BOTTOM;
    pub const SE_BIT_GEOCTR_NO_ECL_LAT = sweph.SE_BIT_GEOCTR_NO_ECL_LAT;
    pub const SE_BIT_NO_REFRACTION = sweph.SE_BIT_NO_REFRACTION;
    pub const SE_BIT_CIVIL_TWILIGHT = sweph.SE_BIT_CIVIL_TWILIGHT;
    pub const SE_BIT_NAUTIC_TWILIGHT = sweph.SE_BIT_NAUTIC_TWILIGHT;
    pub const SE_BIT_ASTRO_TWILIGHT = sweph.SE_BIT_ASTRO_TWILIGHT;
    pub const SE_BIT_FIXED_DISC_SIZE = sweph.SE_BIT_FIXED_DISC_SIZE;
    pub const SE_BIT_FORCE_SLOW_METHOD = sweph.SE_BIT_FORCE_SLOW_METHOD;
    pub const SE_BIT_HINDU_RISING = sweph.SE_BIT_HINDU_RISING;

    pub const SE_ECL2HOR = sweph.SE_ECL2HOR;
    pub const SE_EQU2HOR = sweph.SE_EQU2HOR;
    pub const SE_HOR2ECL = sweph.SE_HOR2ECL;
    pub const SE_HOR2EQU = sweph.SE_HOR2EQU;

    pub const SE_TRUE_TO_APP = sweph.SE_TRUE_TO_APP;
    pub const SE_APP_TO_TRUE = sweph.SE_APP_TO_TRUE;

    pub const SE_DE_NUMBER = sweph.SE_DE_NUMBER;
    pub const SE_FNAME_DE200 = sweph.SE_FNAME_DE200;
    pub const SE_FNAME_DE403 = sweph.SE_FNAME_DE403;
    pub const SE_FNAME_DE404 = sweph.SE_FNAME_DE404;
    pub const SE_FNAME_DE405 = sweph.SE_FNAME_DE405;
    pub const SE_FNAME_DE406 = sweph.SE_FNAME_DE406;
    pub const SE_FNAME_DE431 = sweph.SE_FNAME_DE431;
    pub const SE_FNAME_DFT = sweph.SE_FNAME_DFT;
    pub const SE_FNAME_DFT2 = sweph.SE_FNAME_DFT2;
    pub const SE_STARFILE_OLD = sweph.SE_STARFILE_OLD;
    pub const SE_STARFILE = sweph.SE_STARFILE;
    pub const SE_ASTNAMFILE = sweph.SE_ASTNAMFILE;
    pub const SE_FICTFILE = sweph.SE_FICTFILE;

    pub const SE_HELIACAL_RISING = sweph.SE_HELIACAL_RISING;
    pub const SE_HELIACAL_SETTING = sweph.SE_HELIACAL_SETTING;
    pub const SE_MORNING_FIRST = sweph.SE_MORNING_FIRST;
    pub const SE_EVENING_LAST = sweph.SE_EVENING_LAST;
    pub const SE_EVENING_FIRST = sweph.SE_EVENING_FIRST;
    pub const SE_MORNING_LAST = sweph.SE_MORNING_LAST;
    pub const SE_ACRONYCHAL_RISING = sweph.SE_ACRONYCHAL_RISING;
    pub const SE_ACRONYCHAL_SETTING = sweph.SE_ACRONYCHAL_SETTING;
    pub const SE_COSMICAL_SETTING = sweph.SE_COSMICAL_SETTING;

    pub const SE_HELFLAG_LONG_SEARCH = sweph.SE_HELFLAG_LONG_SEARCH;
    pub const SE_HELFLAG_HIGH_PRECISION = sweph.SE_HELFLAG_HIGH_PRECISION;
    pub const SE_HELFLAG_OPTICAL_PARAMS = sweph.SE_HELFLAG_OPTICAL_PARAMS;
    pub const SE_HELFLAG_NO_DETAILS = sweph.SE_HELFLAG_NO_DETAILS;
    pub const SE_HELFLAG_SEARCH_1_PERIOD = sweph.SE_HELFLAG_SEARCH_1_PERIOD;
    pub const SE_HELFLAG_VISLIM_DARK = sweph.SE_HELFLAG_VISLIM_DARK;
    pub const SE_HELFLAG_VISLIM_NOMOON = sweph.SE_HELFLAG_VISLIM_NOMOON;
    pub const SE_HELFLAG_VISLIM_PHOTOPIC = sweph.SE_HELFLAG_VISLIM_PHOTOPIC;
    pub const SE_HELFLAG_VISLIM_SCOTOPIC = sweph.SE_HELFLAG_VISLIM_SCOTOPIC;
    pub const SE_HELFLAG_AV = sweph.SE_HELFLAG_AV;
    pub const SE_HELFLAG_AVKIND_VR = sweph.SE_HELFLAG_AVKIND_VR;
    pub const SE_HELFLAG_AVKIND_PTO = sweph.SE_HELFLAG_AVKIND_PTO;
    pub const SE_HELFLAG_AVKIND_MIN7 = sweph.SE_HELFLAG_AVKIND_MIN7;
    pub const SE_HELFLAG_AVKIND_MIN9 = sweph.SE_HELFLAG_AVKIND_MIN9;
    pub const SE_HELFLAG_AVKIND = sweph.SE_HELFLAG_AVKIND;
    pub const TJD_INVALID = sweph.TJD_INVALID;
    pub const SIMULATE_VICTORVB = sweph.SIMULATE_VICTORVB;

    pub const CROSS_PRECISION = (1 / 3600000.0); // one milliarc sec
};
