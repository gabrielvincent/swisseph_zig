const std = @import("std");
const sweph = @cImport({
    // Include the swisseph header
    @cInclude("swephexp.h");
});

pub const CalcOut = struct {
    lon: f64,
    lat: f64,
    distance: f64,
    lon_speed: f64,
    lat_speed: f64,
    distance_speed: f64,
};

const SweErr = error{
    Generic,
};

const ErrCtx = struct {
    err: anyerror,
    msg: []const u8,

    fn create(err: anyerror, msg: []const u8) ErrCtx {
        return .{ .err = err, .msg = msg };
    }
};

pub fn calc(jd: f64, ipl: i32, iflag: i32, serr: ?*[256]u8) SweErr!CalcOut {
    var xxret: [6]f64 = undefined;
    var err_str: [256]u8 = undefined;
    @memset(&err_str, 0);

    const ret_flag = sweph.swe_calc(jd, ipl, iflag, &xxret, &err_str);

    if (ret_flag < 0) {
        if (serr) |s| {
            @memcpy(s, &err_str);
        }
        return SweErr.Generic;
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
};
