const std = @import("std");
const print = std.debug.print;
const _curses = @cImport(@cInclude("curses.h"));
const kbhit = @import("./kbhit.zig");

pub const KeyEnum = enum {
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    UnkownKey,
    //... -> adicionar restante
};

pub const CWindowPtr = [*c]_curses.WINDOW;

pub const KeyStruct = struct {
    event: KeyEnum,
    code: u16,

    pub fn init(code: u16) KeyStruct {
        const event: KeyEnum = switch (code) {
            _curses.KEY_UP => .ArrowUp,
            _curses.KEY_DOWN => .ArrowDown,
            _curses.KEY_LEFT => .ArrowLeft,
            _curses.KEY_RIGHT => .ArrowRight,
            else => .UnkownKey,
        };

        return .{
            .code = code,
            .event = event,
        };
    }
};

pub const Curses = struct {
    WINDOW: [*c]_curses.WINDOW,

    const Self = @This();

    pub fn init() Curses {
        const screen = _curses.initscr();
        _ = _curses.keypad(screen, true);
        _ = _curses.clear();
        _ = _curses.noecho();
        _ = _curses.cbreak();
        return .{ .WINDOW = screen };
    }

    pub fn renderChar(self: Self, char: u8, place: []i16) !void {
        _ = self;
        _ = _curses.mvaddch(@intCast(place[1]), @intCast(place[0]), char);
    }

    pub fn clearScreen(self: Self) void {
        _ = self;
        _ = _curses.clear();
    }

    pub fn updateFullScreen(self: Self) void {
        _ = self;
        _ = _curses.refresh();
    }

    pub fn getScreenWidth(self: Self) i16 {
        return @intCast(_curses.getmaxy(self.WINDOW));
    }

    pub fn getScreenHeight(self: Self) i16 {
        return @intCast(_curses.getmaxx(self.WINDOW));
    }

    pub fn getKeyPressedFreeze(self: Self) KeyStruct {
        _ = self;
        const _key: u16 = @intCast(_curses.getch());

        return KeyStruct.init(_key);
    }

    pub fn deinit(self: Self) void {
        _ = self;
        _ = _curses.endwin();
    }
};
