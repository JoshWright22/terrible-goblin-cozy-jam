# Slush Rush

A cozy puzzle game about making the best smoothies in the world.

Summer has arrived and the smoothie bar is open. Drag fruit off the conveyor, rotate and pack it into the blender, then blend drinks that match each customer's order before they lose patience.

Originally made for **Comfy Jam: Summer 2026**. The jam version is free to play on [itch.io](https://joshwright.itch.io/slush-rush). The full release is in development for Steam and Android. See [GDD.md](GDD.md) for the plan.

## Controls

| Action | Mouse |
| --- | --- |
| Pick up and drag fruit | Hold left click |
| Rotate a held piece | Right click |
| Blend | Click the Blend button |
| Serve | Drag the smoothie onto the customer |

## Running the project

1. Install [Godot 4.6](https://godotengine.org/download).
2. Open `project.godot` in Godot.
3. Press F5 to run from the main menu.

## Project layout

| Folder | Contents |
| --- | --- |
| `Scenes/` | Game scenes. `Primary/` has the menu, game loop, settings and credits |
| `Scripts/` | Game logic. `Grid/` has the blender grid and draggable pieces |
| `Resource/` | Fruit piece data (fruit type × shape) |
| `Assets/` | Sprites, fonts and sound |
| `Shaders/` | Conveyor and visual effect shaders |

Autoloads: `GameManager` (shared game state), `AudioManager` (sound effects and music), `SaveManager` (settings and progress, saved to `user://save.cfg`).

## Credits

- Joshua Wright: Godot dev
- Jack (H4rb1nger): Godot dev
- Robert Taquechel: Godot dev
- Aurora (Roranart): Art
- Nivadra: Music

Sound effects by [Kenney](https://kenney.nl). "Magic Yellow" font by Syaf Rizal (Khurasan TM), to be replaced for the commercial release.
