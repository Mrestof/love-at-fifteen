Love at Fifteen - a simple game written in Lua as my first game project,
using LÖVE, which implements the simple 15 puzzle.


Getting LÖVE:
  https://www.love2d.org/

Building for your platform:
  https://www.love2d.org/wiki/Game_Distribution


Running from source:
  `love ./`

Controls, two options:
  - arrows
  - numpad arrows (or 2468)
  - vim-like motions (hjkl)
  - touches or mouse clicks on the tiles adjacent to an empty space

Goal of the game:
  In order to solve the puzzle, you need to order all the tiles correctly, so
  that the final grid looks like this:
  +--+--+--+--+
  |1 |2 |3 |4 |
  +--+--+--+--+
  |5 |6 |7 |8 |
  +--+--+--+--+
  |9 |10|11|12|
  +--+--+--+--+
  |13|14|15|__|
  +--+--+--+--+


P.S.
There's a little win screen at the end, so it's worth playing at least once ;)
Warning: win screen includes sound and somewhat flashing image.
