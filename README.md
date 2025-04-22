# swisseph_zig - Zig interface binding for the Swiss Ephemeris C library

## Installation

Follow these steps to set up the Swiss Ephemeris library with your Zig project:

1. Clone the official swisseph repository:

   ```bash
   git clone https://github.com/aloistr/swisseph.git
   ```

2. Build it as a static library:

   ```bash
   cd swisseph
   make libswe.a
   ```

3. In the root of your project, create a directory called `swisseph`:

   ```bash
   mkdir -p path/to/your_project/swisseph
   ```

4. Copy the following files to your project:

   ```bash
   cp path/to/swisseph/libswe.a path/to/your_project/swisseph
   cp path/to/swisseph/swephexp.h path/to/your_project/swisseph
   cp path/to/swisseph/sweodef.h path/to/your_project/swisseph
   ```

5. Add swisseph_zig as a dependency in your `build.zig.zon` file:

   ```zig
   .swisseph_zig = .{
       .url = "github.com/gabrielvincent/swisseph_zig",
   },
   ```

6. Add swisseph_zig as module for your executable in `build.zig`:

   ```zig
   const exe = b.addExecutable(.{
       .name = "your_project",
       .root_source_file = b.path("src/main.zig"),
       .target = target,
       .optimize = optimize,
   });

   const swisseph_dir_opt = b.option(
       []const u8,
       "swisseph-dir",
       "Path to Swiss Ephemeris files (libswe.a, swephexp.h, sweodef.h)",
   ) orelse "swisseph";

   // Get the swisseph_zig dependency, passing the option to it
   const sweph_dep = b.dependency("swisseph_zig", .{
       .target = target,
       .optimize = optimize,
       .swisseph_dir = swisseph_dir_opt,
   });

   const sweph_mod = sweph_dep.module("swisseph_zig");
   sweph_mod.addIncludePath(b.path(swisseph_dir_opt));
   sweph_mod.addObjectFile(b.path(b.fmt("{s}/libswe.a", .{swisseph_dir_opt})));

   exe.root_module.addImport("swisseph_zig", sweph_dep.module("swisseph_zig"));
   ```

## Usage

Here's a simple example of how to use the library in your Zig code:

```zig
const std = @import("std");
const sweph = @import("swisseph_zig");

pub fn main() !void {
    const julday: f64 = 2459000.5; // Example Julian day
    const eph = sweph.swe_calc_ut(julday, .SUN, .JPLEPH) catch |err| {
        std.debug.print("Failed to get ephemeris: {}", .{err});
        return;
    };

    std.debug.print("Sun position: {d:.6}\n", .{eph.lon});
    std.debug.print("Sun speed: {d:.6}\n", .{eph.lon_speed});
}
```
