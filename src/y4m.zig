const std = @import("std");
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const fmt = std.fmt;

pub const Y4MSignature = "YUV4MPEG2";

pub const Color = enum {
    unknown,
    i420,
    i422,
};

pub const Y4MHeader = struct {
    width: u16,
    height: u16,
    frame_rate: u32,
    time_scale: u32,
    color: Color,

    const Self = @This();

    pub fn frameSize(self: *Self) !u32 {
        switch (self.color) {
            Color.i420 => {
                return self.width * self.height * 3 / 2;
            },
            Color.i422 => {
                return self.width * self.height * 2;
            },
            else => {
                return error.Y4MFormat;
            },
        }
    }

    pub fn colorStr(self: *const Self) ![]const u8 {
        switch (self.color) {
            Color.i420 => {
                return "420";
            },
            Color.i422 => {
                return "422";
            },
            else => {
                return error.Y4MFormat;
            },
        }
    }
};

pub const Y4MReader = struct {
    header: Y4MHeader,
    file: fs.File,
    frame_size: u32,

    const Self = @This();

    pub fn init(file: fs.File) !Y4MReader {
        var self = Y4MReader{
            .file = file,
            .header = undefined,
            .frame_size = undefined,
        };
        self.header.color = Color.unknown;
        try self.readY4MHeader();
        self.frame_size = try self.header.frameSize();
        return self;
    }

    pub fn deinit(_: *Self) void {}

    fn readY4MHeader(self: *Self) !void {
        var r = self.file.reader();
        var buf: [1024]u8 = undefined;

        // Read until '\n'
        var count: u32 = 0;
        while (true) : (count += 1) {
            if (count >= buf.len) {
                return error.Y4MFormat;
            }
            buf[count] = try r.readByte();
            if (buf[count] == '\n') {
                break;
            }
        }
        if (count == 0) {
            return error.Y4MFormat;
        }

        var it = mem.split(u8, buf[0..count], " ");
        if (it.next()) |v| {
            if (!mem.eql(u8, v, Y4MSignature)) {
                return error.Y4MFormat;
            }
        }
        while (it.next()) |v| {
            switch (v[0]) {
                'C' => {
                    if (mem.eql(u8, v[1..], "420")) {
                        self.header.color = Color.i420;
                    } else if (mem.eql(u8, v[1..], "422")) {
                        self.header.color = Color.i422;
                    } else {
                        self.header.color = Color.unknown;
                    }
                },
                'W' => {
                    self.header.width = try fmt.parseInt(u16, v[1..], 10);
                },
                'H' => {
                    self.header.height = try fmt.parseInt(u16, v[1..], 10);
                },
                'F' => {
                    var it2 = mem.split(u8, v[1..], ":");
                    if (it2.next()) |v2| {
                        self.header.frame_rate = try fmt.parseInt(u32, v2, 10);
                    } else {
                        return error.Y4MFormat;
                    }
                    if (it2.next()) |v2| {
                        self.header.time_scale = try fmt.parseInt(u32, v2, 10);
                    } else {
                        return error.Y4MFormat;
                    }
                },
                'I' => {
                    if (!mem.eql(u8, v[1..], "p")) {
                        return error.Y4MNotSupported;
                    }
                },
                'A' => {
                    if (!mem.eql(u8, v[1..], "1:1")) {
                        return error.Y4MNotSupported;
                    }
                },
                else => {},
            }
        }
    }

    pub fn readFrame(self: *Self, frame: []u8) !usize {
        const frame_header = "FRAME\n";
        var buf: [frame_header.len]u8 = undefined;
        if (frame_header.len != try self.file.readAll(&buf)) {
            return error.EndOfStream;
        }
        if (!mem.eql(u8, &buf, frame_header)) {
            return error.Y4MFormat;
        }
        return try self.file.readAll(frame);
    }

    pub fn skipFrame(self: *Self) !void {
        const frame_header = "FRAME\n";
        var buf: [frame_header.len]u8 = undefined;
        if (frame_header.len != try self.file.readAll(&buf)) {
            return error.EndOfStream;
        }
        if (!mem.eql(u8, &buf, frame_header)) {
            return error.Y4MFormat;
        }
        try self.file.seekBy(self.frame_size);
    }
};

pub const Y4MWriter = struct {
    file: fs.File,

    const Self = @This();

    pub fn init(file: fs.File, header: *const Y4MHeader) !Y4MWriter {
        var self = Y4MWriter{
            .file = file,
        };
        try self.writeY4MHeader(header);
        return self;
    }

    pub fn deinit(_: *Self) void {}

    fn writeY4MHeader(self: *Self, header: *const Y4MHeader) !void {
        var buf: [1024]u8 = undefined;
        const color_str = try header.colorStr();
        const data = try std.fmt.bufPrint(&buf, "{s} C{s} W{d} H{d} Ip F{d}:{d} A1:1\n", .{
            Y4MSignature,
            color_str,
            header.width,
            header.height,
            header.frame_rate,
            header.time_scale,
        });
        try self.file.writeAll(data);
    }

    pub fn writeY4MFrame(self: *Self, frame: []const u8) !void {
        const frame_header = "FRAME\n";
        try self.file.writeAll(frame_header);
        try self.file.writeAll(frame);
    }
};
