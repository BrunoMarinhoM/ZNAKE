const std = @import("std");
const print = std.debug.print;
const c_stdio = @cImport(@cInclude("stdio.h"));
const posix = std.posix;

pub fn kbhit() !usize {
    const stdin = std.io.getStdIn();

    var termios = try posix.tcgetattr(stdin.handle);

    termios.lflag.ICANON = false;

    try posix.tcsetattr(stdin.handle, .NOW, termios);

    _ = c_stdio.setbuf(c_stdio.stdin, 0);

    var bytesWaiting: usize = 0;

    _ = std.c.ioctl(stdin.handle, 0x541B, &bytesWaiting);

    return bytesWaiting;
}

pub fn main() !void {
    while (true) {
        print("{any}\n", .{kbhit()});
    }
}
