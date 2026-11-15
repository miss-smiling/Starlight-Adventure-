# Pixel Art Drop-In Folder

Upload your pixel art here and the game picks it up automatically. Any image
that is missing is replaced by the built-in code-drawn / flat-styled look, so
you can add files one at a time and the game never breaks.

All files are PNG. Use the exact names below (all lowercase). Portraits,
panels and frames are drawn with nearest-neighbour filtering, so keep the
pixels square (export without smoothing).

## `portraits/` - character art

One PNG per character, named by the profession id (lowercase, exact):

| File name         | Used in                                          |
| ----------------- | ------------------------------------------------ |
| `astronaut.png`   | Squad slot + dialogue portrait                   |
| `engineer.png`    | Squad slot + dialogue portrait                   |
| `physicist.png`   | Squad slot + dialogue portrait                   |
| `mathematician.png` | Squad slot + dialogue portrait                 |
| `biologist.png`   | Squad slot + dialogue portrait                   |
| `medical.png`     | Squad slot + dialogue portrait                   |
| `comms.png`       | Squad slot + dialogue portrait                   |
| `director.png`    | Squad slot + dialogue portrait                   |

Any other name (e.g. `mission_command.png`) is used automatically as the
dialogue portrait whenever a speaker with that id talks - so you can add art
for extra NPC speakers without changing any code.

Guidance: roughly square, character centred, head and shoulders filling most
of the frame, transparent background. Any size works; it is scaled to fit.

## `icons/` - small badges

| File name         | Used in                                          |
| ----------------- | ------------------------------------------------ |
| `astronaut.png`   | Task title bar badge + operator file panel       |
| `engineer.png`    | Task title bar badge + operator file panel       |
| `physicist.png`   | Task title bar badge + operator file panel       |
| `mathematician.png` | Task title bar badge + operator file panel     |
| `biologist.png`   | Task title bar badge + operator file panel       |
| `medical.png`     | Task title bar badge + operator file panel       |
| `comms.png`       | Task title bar badge + operator file panel       |
| `director.png`    | Task title bar badge + operator file panel       |

Small square symbols (32x32 or 64x64 work best). They show next to the task
title and in the operator file; the squad slots always use the full
`portraits/` art when available, so icons can be simpler symbols.

## `scenes/` - full-screen backdrops

| File name | Used in                                            |
| --------- | -------------------------------------------------- |
| `city.png` | Main menu night-city skyline (replaces built-in)  |
| `space.png` | Global deep-space background (starfield dots stay animated on top) |
| `control_room.png` | Mission-shift screen backdrop (behind the panels) |

Make it 1280x720 (or a 2x/4x pixel resolution like 640x360 or 320x180). It is
scaled to cover the whole window.

## `ui/` - frames, buttons and chat box

These replace the flat-styled look everywhere at once. Draw them as framed
rectangles; the corners (12px) are preserved and the middle stretches, so a
small image works for panels of any size.

| File name                | Used in                                              |
| ------------------------ | ---------------------------------------------------- |
| `panel.png`              | Every panel / popup frame in the game                |
| `button.png`             | Every secondary button (dark navy style)             |
| `button_hover.png`       | Secondary button hover state (optional)              |
| `button_primary.png`     | Every golden primary action button                   |
| `button_primary_hover.png` | Primary button hover state (optional)              |
| `logo.png`               | Main menu logo (replaces the plain text title)       |
| `panel_accent.png`       | Field-tips panel frame (cyan-edged)                  |
| `panel_gold.png`         | Skip-confirmation panel frame (gold-edged)           |
| `panel_edge.png`         | Dialogue / chat panel frame                          |
| `cute panel.png`         | All popups (journal, pause, results)                 |
| `panel corner fold.png`  | Shift checklist side panel during missions           |
| `panel electric.png`     | Operator file panel on profession select             |
| `spaceship view.png`     | Backdrop behind team discussions (dimmed, covered)   |

Panel variants keep the game's flat fallback colors when absent, so each
looks distinct even without uploads.

Button guidance: a simple bordered rectangle reads best; the game tints it
slightly brighter on hover and darker while pressed, so one image per state
is enough. Text is drawn on top by the game - leave the middle clear.

## `icons/hint.png` - HINT button badge

Any small symbol here appears inside every HINT button next to the word.

## Palette advice (so it matches the visual direction)

Deep navy, dark blue, electric blue, cyan, white, warm golden-orange. Avoid
pink/purple; the UI will clash otherwise.

## Quiz + puzzle content (edit the data files, not code)

- `data/quiz.json` - the certification quiz. One section per profession plus
  a "general" fallback: `{"questions": [{"q": "...", "choices": ["..","..","..",".."], "answer": 0}]}`.
  The quiz shows however many questions exist; add up to 10 per profession.
- `data/puzzles.json` - the two puzzle games per profession (`cross` and
  `final`). Each entry has a `type`: `matiks` (quick math), `sudoku` (4x4
  grid), `pinpoint` (narrowing clues), `crossclimb` (word ladder), `tango`
  (power grid). Edit grids, ladders and answers here.


## `game/` - arcade finale sprites

| File name | Used in |
| --------- | ------- |
| `shooting game backgraund.png` | Debris-run starfield backdrop (yes, with the typo in the filename) |
| `shooting game spaceship.png` | The player spacecraft |
| `asteroid.png` | Obstacle sprite (rock kind) |
| `fireball blue.png` | Obstacle sprite (blue fireball kind) |
| `fireball red.png` | Obstacle sprite (red fireball kind) |

Each obstacle picks one of the three sprites at random; two-hit rocks are
bigger and flash a gold rim near the ship. Any sprite missing = code-drawn
fallback for that thing only.


## After uploading (one-time step)

Godot imports images when the project is opened. If you added files while the
game was closed, either:

1. Open the project once in the Godot editor (it imports everything), or
2. Run the import from the command line:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
```

Then just run the game - new art appears everywhere by itself.
