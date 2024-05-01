const std = @import("std");
const print = std.debug.print;
const curses = @cImport(@cInclude("curses.h"));
const kbhit = @import("./kbhit_2.zig");

const Snake = struct {
    allocator: std.mem.Allocator,
    head_pos: []i16,
    //should always be +1 or -1 for either of the coordinates
    head_speed: []i16,
    size: *usize,
    history_path: *std.ArrayList([]i16),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, x_init: i16, y_init: i16, x_speed_init: i16, y_speed_init: i16) !Snake {
        const size = try allocator.create(usize);
        const head_pos = try allocator.alloc(i16, 2);
        const head_speed = try allocator.alloc(i16, 2);
        var history_path = try allocator.create(std.ArrayList([]i16));
        history_path.* = std.ArrayList([]i16).init(allocator);
        head_speed[1] = x_speed_init;
        head_speed[0] = y_speed_init;
        head_pos[1] = x_init;
        head_pos[0] = y_init;
        size.* = 1;
        try history_path.append(head_pos);

        return .{
            .allocator = allocator,
            .size = size,
            .head_pos = head_pos,
            .head_speed = head_speed,
            .history_path = history_path,
        };
    }

    pub fn deinit(self: Self) void {
        for (self.history_path.*.items) |body_slice| {
            self.allocator.free(body_slice);
        }
    }

    pub fn walk(self: *Self) void {
        for (0..self.history_path.*.items.len - 1) |ind| {
            self.history_path.*.items[ind][0] = self.history_path.*.items[ind + 1][0];
            self.history_path.*.items[ind][1] = self.history_path.*.items[ind + 1][1];
        }
        self.history_path.*.items[self.history_path.*.items.len - 1][0] += self.head_speed[0];
        self.history_path.*.items[self.history_path.*.items.len - 1][1] += self.head_speed[1];
    }

    pub fn eat(self: Self) !void {
        self.size.* = self.size.* + 1;
        const head_new_pos = try self.allocator.alloc(i16, 2);
        head_new_pos[0] = self.history_path.*.items[0][0] - self.head_speed[0];
        head_new_pos[1] = self.history_path.*.items[0][1] - self.head_speed[1];

        try self.history_path.insert(0, head_new_pos);
    }

    pub fn setSpeed(self: Self, x_speed: i16, y_speed: i16) void {
        self.head_speed[1] = x_speed;
        self.head_speed[0] = y_speed;
    }

    pub fn getSpeed(self: Self) []i16 {
        return self.head_speed;
    }

    pub fn getHeadPosition(self: Self) []i16 {
        return self.head_pos;
    }
};

pub fn renderSnake(s: *Snake, window: [*c]const curses.WINDOW) void {
    const max_x: i16 = @intCast(curses.getmaxx(window));
    const max_y: i16 = @intCast(curses.getmaxy(window));
    if (s.head_pos[1] == max_x) {
        s.head_pos[1] = 0;
    } else if (s.head_pos[1] == -1) {
        s.head_pos[1] = @intCast(curses.getmaxx(window) - 1);
    }

    if (s.head_pos[0] == max_y) {
        s.head_pos[0] = 0;
    } else if (s.head_pos[0] == -1) {
        s.head_pos[0] = @intCast(curses.getmaxy(window) - 1);
    }

    for (s.history_path.*.items, 0..) |body_slice, ind| {
        const snake = "SNAKE|";
        _ = curses.mvaddch(@intCast(body_slice[0]), @intCast(body_slice[1]), snake.*[@mod(ind, snake.len)]);
    }
}

pub fn renderFood(pos: []i16) void {
    _ = curses.mvaddch(pos[0], pos[1], "0".*[0]);
}

pub fn spawnFood(window: [*c]const curses.WINDOW, buff: ?[]i16) ![]i16 {
    const most_y: i16 = @intCast(curses.getmaxy(window));
    const most_x: i16 = @intCast(curses.getmaxx(window));

    if (buff) |buffer| {
        buffer[1] = std.crypto.random.intRangeAtMost(i16, 2, most_x);
        buffer[0] = std.crypto.random.intRangeAtMost(i16, 2, most_y);

        return buffer;
    }

    const new_buffer = try std.heap.page_allocator.alloc(i16, 2);

    new_buffer[1] = std.crypto.random.intRangeAtMost(i16, 2, most_x);
    new_buffer[0] = std.crypto.random.intRangeAtMost(i16, 2, most_y);

    return new_buffer;
}

pub fn isEqlSlice(T: type, a: []T, b: []T) bool {
    if (a.len != b.len) {
        return false;
    }

    for (0..a.len) |ind| {
        if (a[ind] != b[ind]) {
            return false;
        }
    }

    return true;
}

pub fn main() !void {
    // var hit_counter: u128 = 0;

    // initializes screen, set curses.col, etc...
    const screen = curses.initscr();

    const kpad = curses.keypad(screen, true);

    _ = kpad;

    _ = curses.clear();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var snake_test = try Snake.init(allocator, 10, 10, 1, 0);

    for (0..4) |_| {
        try snake_test.eat();
    }

    var running: bool = true;

    renderSnake(&snake_test, screen);

    const food_pos = try spawnFood(screen, null);

    renderFood(food_pos);

    // var last_hit_lagged: u8 = 0;

    game: while (running) {
        _ = curses.clear();

        snake_test.walk();

        for (snake_test.history_path.*.items[0 .. snake_test.history_path.*.items.len - 1]) |body_slice| {
            if (isEqlSlice(i16, body_slice, snake_test.head_pos)) {
                const posx = @divTrunc(curses.getmaxx(screen), 2);
                const posy = @divTrunc(curses.getmaxy(screen), 2);
                for ("YOU DIED".*, 0..) |ch, ind| {
                    const _ind: c_int = @intCast(ind);
                    _ = curses.mvaddch(posx + _ind, posy + _ind, ch);
                }

                _ = curses.refresh();
                std.time.sleep(1000000000);
                break :game;
            }
        }

        if (isEqlSlice(i16, snake_test.getHeadPosition(), food_pos)) {
            try snake_test.eat();
            _ = try spawnFood(screen, food_pos);
            renderFood(food_pos);
        }

        renderSnake(&snake_test, screen);

        renderFood(food_pos);

        if (snake_test.getSpeed()[1] == 0) std.time.sleep(100000000) else std.time.sleep(63000000);

        _ = curses.refresh();

        const internal_hit_counter = try kbhit.kbhit();

        if (internal_hit_counter != 0) {
            const key_pressed = curses.getch();
            switch (key_pressed) {
                curses.KEY_UP => {
                    if (snake_test.getSpeed()[1] != 0) {
                        snake_test.setSpeed(0, -1);
                    }
                },

                curses.KEY_DOWN => {
                    if (snake_test.getSpeed()[1] != 0) {
                        snake_test.setSpeed(0, 1);
                    }
                },

                curses.KEY_LEFT => {
                    if (snake_test.getSpeed()[0] != 0) {
                        snake_test.setSpeed(-1, 0);
                    }
                },

                curses.KEY_RIGHT => {
                    if (snake_test.getSpeed()[0] != 0) {
                        snake_test.setSpeed(1, 0);
                    }
                },

                //esc
                27 => {
                    running = false;
                },

                //enter
                10 => {
                    _ = try spawnFood(screen, food_pos);
                    renderFood(food_pos);
                },

                else => {},
            }
        }
    }
    _ = curses.endwin();

    snake_test.deinit();

    std.heap.page_allocator.free(food_pos);
}
