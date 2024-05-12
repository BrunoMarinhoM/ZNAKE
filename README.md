An in-terminal snake game build entirely in ZIG with as few as I could make
direct C imports and C-exclusive features.

Only working on linux with minimal interface.

Run:

Assure you have installed zig version 0.12 and simply run

zig build-exe ./src/main.zig -lc -lcurses

you should then run ./main and have fun playing it;

Many many changes and refactorizations are pendent.
