# Croptopia - Rarer Fruit Trees

A datapack that overrides Croptopia's world-generation files to make all
27 fruit/nut trees spawn less often in the world, and fixes the 9
jungle-fruit trees so they can actually spawn in worlds (like
*Create Beyond Ruin*'s) that only generate `bamboo_jungle` instead of
plain `jungle`. It doesn't touch crops, salt deposits, or anything else
Croptopia adds — just the trees.

Built for **Croptopia 4.2.4** on **NeoForge 1.21.1** (as used in the
*Create Beyond Ruin* modpack). It's a plain data pack, so it works
whether or not you're using NeoForge, as long as Croptopia itself is
installed.

## Part 1: rarity

Currently uses **two multipliers, grouped by placement mechanism**
(not trunk type — see "How it works" below for why):

| Group | Trees | Multiplier |
|---|---|---|
| `rarity_filter` trees | apple, apricot, avocado, banana, cherry, date, dragonfruit, fig, grapefruit, kumquat, lemon, lime, mango, nectarine, nutmeg, orange, peach, pear, persimmon, plum, starfruit (21 trees) | **50x** |
| weighted-list trees | almond, cashew, cinnamon, coconut, pecan, walnut (6 trees) | **10x** |

These values were picked to match how apple (rarity_filter) and almond
(weighted-list) felt in testing — every other tree using the same
underlying mechanism now gets the same multiplier, so the whole pack
should feel roughly as rare as those two did.

### How it works

Croptopia decides where trees generate using `worldgen/placed_feature`
JSON files — each one has either:

- a `minecraft:rarity_filter` with a `chance` number (bigger = rarer,
  it's a 1-in-`chance` roll), or
- a `minecraft:count` weighted list that picks between "no tree" and
  "a small cluster" with certain odds (almond, cashew, cinnamon,
  coconut, pecan, walnut).

Which mechanism a tree uses (not what its trunk looks like) is what
actually determines how a given multiplier number "feels" in-game —
that's why the tiers are grouped this way instead of by trunk block.

A regular data pack can't "multiply an existing value" — it can only
replace a file outright. So this pack ships already-computed, scaled
copies of all 27 files in `data/croptopia/worldgen/placed_feature/`.
Because a data pack with the same namespace+path as a mod's file wins
by load order, these override Croptopia's originals.

### Changing the rarity later

Two numbers near the top of [`generate.ps1`](generate.ps1) control this:

```powershell
$RarityFilterMultiplier = 50
$WeightedListMultiplier = 10
```

1. Open `generate.ps1` in a text editor.
2. Change either number:
   - `1` = same as vanilla Croptopia
   - `2` = twice as rare
   - `50` = fifty times as rare
   - `0.5` = **more common** than vanilla (numbers below 1 work too)
3. Save, then re-run the script — right-click it and choose
   "Run with PowerShell", or from a PowerShell prompt:

   ```powershell
   ./generate.ps1
   ```

   The script auto-detects which mechanism each of the 27 files uses,
   so you never need to maintain a tree name list — just the two
   numbers. It always regenerates from the untouched copies in
   `originals/`, so you can go up or down as many times as you like
   without the numbers drifting.
4. Redeploy (see Installing below) and run `/reload` in-game.

If you'd rather hand-edit a single tree instead of using the script,
open its file in `data/croptopia/worldgen/placed_feature/` — e.g.
`apple_tree_placed.json` — and change the `"chance"` number directly
(bigger = rarer). For the six weighted-list trees, raise the `weight`
of the lowest `data` entry to make that tree rarer.

### What changed at the current settings

| Tree | Original | New |
|---|---|---|
| apple, apricot, avocado, banana, cherry, date, dragonfruit, fig, grapefruit, kumquat, lemon, lime, mango, nectarine, nutmeg, orange, peach, pear, persimmon, plum, starfruit (50x) | 1-in-10 chance | 1-in-500 chance |
| almond, cashew, pecan, walnut (10x) | 25% chance of a 5-sapling cluster | 2.5% chance of a 5-sapling cluster |
| coconut (10x) | 20% chance of a 5-sapling cluster | ~2% chance of a 5-sapling cluster |
| cinnamon (10x) | ~10% chance of a bonus 7th sapling (1 sapling otherwise) | ~1% chance of the bonus (1 sapling otherwise) |

## Part 2: the bamboo jungle fix

Croptopia decides *which biomes* a tree is allowed in via biome tags —
`data/croptopia/tags/worldgen/biome/has_tree/<fruit>.json`. For the 9
jungle-fruit trees (banana, coconut, date, dragonfruit, fig, grapefruit,
kumquat, mango, nutmeg), that tag only lists `minecraft:jungle`,
`minecraft:sparse_jungle`, and a couple of Terralith biomes — it never
mentions `minecraft:bamboo_jungle` at all.

*Create Beyond Ruin* ships a `biome_replacer.properties` config that
maps both `minecraft:jungle` and `minecraft:sparse_jungle` to `null`
(they never generate), and Terralith isn't installed either — so none
of Croptopia's listed biomes exist in this world. No amount of rarity
tweaking can fix that; the trees simply had nowhere they were allowed
to spawn.

This pack adds `minecraft:bamboo_jungle` to all 9 of those tags, in
`data/croptopia/tags/worldgen/biome/has_tree/`. Data pack tags **merge**
with the values from other packs by default (they don't replace them
unless a file sets `"replace": true`, which these don't), so this just
adds bamboo jungle as a valid biome alongside whatever Croptopia and
other packs already allow — nothing is removed.

If you ever add back Terralith, Biomes O'Plenty, or another biome mod
with its own jungle-family biomes, and still see a fruit missing, check
that fruit's tag file and add the missing biome ID the same way.

## Part 2b: the savanna crop fix

Croptopia's tags for 8 crops — **ginger, hops, kiwi, leek, olive,
turmeric, yam, zucchini** — only list `minecraft:savanna`,
`minecraft:savanna_plateau`, `minecraft:windswept_savanna`, plus
Terralith/Biomes O'Plenty/Biomes We've Gone biomes. `biome_replacer.properties`
nulls all three vanilla savanna biomes, and none of those other biome
mods are installed — so unlike the jungle case, there's no surviving
savanna-family biome at all to fall back on.

Per your call, these 8 crops' tags now add `minecraft:old_growth_birch_forest`
instead, in `data/croptopia/tags/worldgen/biome/has_crop/`. Same merge
behavior as the bamboo jungle fix — nothing existing is removed, this
just gives them a biome that actually generates in this world.

(`rutabaga` and `squash` weren't touched — they also list savanna
biomes, but they still have working taiga biomes in their tag too, so
they were never fully blocked.)

## Part 3: seeing every tree without hunting for it

The pack includes a function that force-places all 27 trees in a 9x3
grid (10 blocks apart), starting at your position, using vanilla's
`/place feature` command — which ignores both rarity chance *and*
biome restrictions, so you don't need to find the right biome or get
lucky with the roll. It's purely a "does this exist and look right"
check, not a survival-accurate test.

1. Stand somewhere flat and open (a creative flatland/test area is
   ideal — trees need clear space and will look messy if crowded by
   terrain).
2. Make sure cheats/commands are enabled for the world.
3. Run:

   ```
   /function croptopia_rarer_fruit_trees:test_all_trees
   ```

4. Walk the grid — row 1 is almond → coconut, row 2 is date →
   nectarine, row 3 is nutmeg → walnut (alphabetical, 9 per row). Chat
   also prints a confirmation once it's done.

If a tree doesn't appear at all, check `/msg` or chat for a red error
(usually means the feature ID is wrong or something failed to load —
worth reporting back). If a tree appears but looks like bare
log/leaves with no fruit blocks, that's a Croptopia issue, not this
datapack (we never touch `configured_feature`, only rarity and biome
tags).

## Installing it

1. This modpack has **Moonlight Lib**, which reads a global datapack
   folder that applies to every world automatically:
   `<instance>/moonlight-global-datapacks/`. Put (or keep) the whole
   `croptopia_rarer_fruit_trees` folder there.
   - Without Moonlight Lib, you'd instead copy it into a specific
     world's `saves/<world>/datapacks/` folder.
2. Launch/reload the world (`/reload` if it's already open).
3. Confirm it loaded: run `/datapack list enabled` in-game and look
   for `croptopia_rarer_fruit_trees`.

Only affects **newly generated chunks** — trees (and jungle-fruit
availability) in explored terrain won't change retroactively. To test
the bamboo jungle fix, you'll need to explore into (or `/tp` to) an
unexplored bamboo jungle.
