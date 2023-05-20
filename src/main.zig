const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;

const Y4M = @import("y4m.zig");

pub fn main() !void {
    const alc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alc);
    defer std.process.argsFree(alc, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} y4m-file\n", .{args[0]});
        os.exit(1);
    }
    const filename = std.mem.sliceTo(args[1], 0);
    try dumpY4MFile(filename);
}

pub fn dumpY4MFile(filename: []const u8) !void {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();
    var reader = try Y4M.Y4MReader.init(file);
    defer reader.deinit();

    // Print Y4M header information
    std.debug.print("Y4M Header Information:\n", .{});
    std.debug.print("  Coor: {}\n", .{reader.header.color});
    std.debug.print("  Width: {d}\n", .{reader.header.width});
    std.debug.print("  Height: {d}\n", .{reader.header.height});
    std.debug.print("  Num of framerate: {d}\n", .{reader.header.framerate_num});
    std.debug.print("  Den of framerate: {d}\n", .{reader.header.framerate_den});

    // Read Y4M frame headers until the end of the file
    var frame_count: usize = 0;
    while (true) {
        // var y4m_frame_header: Y4M.Y4MFrameHeader = undefined;
        // reader.readY4MFrameHeader(&y4m_frame_header) catch |err| {
        //     if (err == error.EndOfStream) break;
        //     return err;
        // };
        // std.debug.print("Frame {}:{}\n", .{ frame_index, y4m_frame_header });

        // Skip the frame data according to frame_size
        reader.skipFrame() catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };

        frame_count += 1;
    }
    std.debug.print("Frame count = {d}\n", .{frame_count});
}
