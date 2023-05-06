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

fn copyY4M(filename: []const u8, outfiename: []const u8) !void {
    var file = try fs.cwd().openFile(filename, .{});
    defer file.close();
    var outfile = try fs.cwd().createFile(outfiename, .{});
    defer outfile.close();
    var reader = try Y4M.Y4MReader.init(file);
    defer reader.deinit();

    try testing.expect(reader.header.color == Y4M.Color.i420);
    try testing.expect(reader.header.width == 160);
    try testing.expect(reader.header.height == 120);
    try testing.expect(reader.header.frame_rate == 15);
    try testing.expect(reader.header.time_scale == 1);

    var writer = try Y4M.Y4MWriter.init(outfile, &reader.header);
    defer writer.deinit();

    var frame_count: usize = 0;
    var buf: [64 * 1024]u8 = undefined;
    while (true) {
        const frame_size = try reader.header.frameSize();
        _ = reader.readFrame(buf[0..frame_size]) catch |err| {
            if (err == error.EndOfStream) break;
            return err;
        };
        //try testing.expect(frame_size == try reader.readFrame(buf[0..frame_size]));
        try writer.writeY4MFrame(buf[0..frame_size]);

        frame_count += 1;
    }
    try testing.expect(frame_count == 75);
}

test "Y4M writer" {
    try copyY4M("testfiles/sample01_i420.y4m", "testfiles/out.y4m");
    try checkY4M("testfiles/out.y4m");
}
