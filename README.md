# Tree Game

An incremental tree-chopping game set in a woodland village. Chop trees, sell wood, and upgrade.

made with godot

---

> ## ⚠️ WORK IN PROGRESS — NOT FINISHED
>
> This is an unfinished prototype, not a complete game.
> the game is very short at the moment and does not feature a lot of conent

---

## Features

- **Chopping** — swing your axe at grown trees; they fall as physics ragdolls and
  can be picked up and carried.
- **Tree growth cycle** — trees grow through age stages; chopped trees drop **acorns**.
- **Planting** — replant acorns to grow new trees.
- **Selling** — haul logs to the magic well to turn wood into money.
- **Wheelbarrow** — a driveable vehicle for hauling wood.
- **Save system** — crash-safe autosaving.
- **Settings** — resolution, fullscreen, and volume controls.
- **Input glyphs** — on-screen prompts that swap between keyboard and gamepad.

### Villagers

Honestly the NPCs are the part I've put the most work into. They're way more
complicated than they probably look. Each villager walks around the town on its
own, knows where its shop is and how to get back there, and picks the right
standing-around animation for wherever it ends up. They watch you as you walk past
and turn their head to follow you, and if you get far enough round behind them they
give up instead of spinning the whole body around.

The talking is all custom too. Dialogue types itself out one letter at a time with
its own little voice made of random blips, and every character has a different pitch
so they don't all sound the same. Speech bubbles pop in and out depending on how
close you are. There's a whole cutscene layer sitting on top that can take over any
villager and make them walk places and say things, then hand them back once it's
done. The kids even play a proper game of tag with each other.

### Animals

The woodpeckers fly around on their own, swooping between spots and landing on the
ground. If you whistle and tame one it'll go find the nearest tree, land on it and
start pecking away until it falls down, so it basically chops trees for you. The
wild ones just mind their own business and fly off if you get too close.



---

##  In Development

- Buildable structures.
- Seedsman NPC and seed progression.
- Tool & vehicle upgrade chain (better axes, cart, car, chainsaw).
- More tameable forest animals.
- Interior furnishing and polish.

---

## Running

1. Install **Godot 4.7** (Forward+).
2. Open `project.godot` in the editor and press Play.

> Uses `.blend` models directly — Blender may be needed for reimports.

---

## Layout

| Path | Contents |
| --- | --- |
| `scripts/` | Gameplay code |
| `scenes/` | Scene files |
| `models/` | Blender models & textures |
| `shaders/` | GDShader effects |
| `music/`, `sfx/` | Audio |

---

## License

MIT — see [`LICENSE`](LICENSE).
