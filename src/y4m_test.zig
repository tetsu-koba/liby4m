const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;

const Y4M = @import("y4m.zig");

fn checkY4M(filename: []const u8) !void {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();
    var reader = try Y4M.Y4MReader.init(file);
    defer reader.deinit();

    try testing.expect(reader.header.color == Y4M.Color.i420);
    try testing.expect(reader.header.width == 160);
    try testing.expect(reader.header.height == 120);
    try testing.expect(reader.header.frame_rate == 15);
    try testing.expect(reader.header.time_scale == 1);

    var frame_count: usize = 0;
    while (true) {
        reader.skipFrame() catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        frame_count += 1;
    }
    try testing.expect(frame_count == 75);
}

test "Y4M reader" {
    try checkY4M("testfiles/sample01_i420.y4m");
}

// fn copyY4M(dirname: []const u8, filename: []const u8, outfiename: []const u8) !void {
//     var dir = try fs.cwd().openDir(dirname, .{});
//     defer dir.close();
//     var file = try dir.openFile(filename, .{});
//     defer file.close();
//     var outfile = try dir.createFile(outfiename, .{});
//     defer outfile.close();
//     var reader = try Y4M.Y4MReader.init(file);
//     defer reader.deinit();

//     try testing.expectEqualSlices(u8, &reader.header.fourcc, "VP80");
//     try testing.expect(reader.header.width == 160);
//     try testing.expect(reader.header.height == 120);
//     try testing.expect(reader.header.frame_rate == 15);
//     try testing.expect(reader.header.time_scale == 1);
//     try testing.expect(reader.header.num_frames == 75);

//     var writer = try Y4M.Y4MWriter.init(outfile, &reader.header);
//     defer writer.deinit();

//     var frame_index: usize = 0;
//     var buf: [64 * 1024]u8 = undefined;
//     while (true) {
//         var y4m_frame_header: Y4M.Y4MFrameHeader = undefined;
//         reader.readY4MFrameHeader(&y4m_frame_header) catch |err| {
//             if (err == error.EndOfStream) break;
//             return err;
//         };
//         try testing.expect(y4m_frame_header.timestamp == frame_index);

//         try testing.expect(y4m_frame_header.frame_size == try reader.readFrame(buf[0..y4m_frame_header.frame_size]));
//         try writer.writeY4MFrame(buf[0..y4m_frame_header.frame_size], y4m_frame_header.timestamp);

//         frame_index += 1;
//     }
// }

// test "Y4M writer" {
//     try copyY4M("testfiles", "sample01_i420.y4m", "out.y4m");
//     try checkY4M("testfiles", "out.y4m");
// }
