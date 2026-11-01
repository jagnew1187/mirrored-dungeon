# Mirrored Dungeon — Godot Pass 07

Pass 07 adds detailed woodland, civilian buildings, distinct enemy silhouettes, directional hero attack treatments and clearer ability effects. See [PASS07_REPORT.md](PASS07_REPORT.md) for the 184 passing engine checks, screenshots, performance observations and remaining animation work. Full desktop acceptance is incomplete; further Computer Use testing was omitted at the user's request. The JavaScript game is preserved separately.

## Open on Windows

1. Extract **MirroredDungeon_Godot_Pass07_20261101.zip** completely.
2. In Godot 4.7.2 Standard Project Manager choose **Import**, then `godot-poc/project.godot` and **Import & Edit**.
3. Allow asset import, then press **F5**. Choose **New Campaign**, optionally enter a name, and select Knight, Mage or Rogue. **Continue** opens an existing separate hero slot.

Uses the Compatibility renderer. No C#, plugins, Python, Node, JavaScript repository or network service is required to play. Earlier Godot versions are untested. The original POC ZIP is an older build and is deliberately preserved.

## Play

- WASD/arrows move. Left click walks, approaches NPCs, collects loot or approaches and attacks a selected enemy. Manual movement cancels automatic approach.
- Space/right mouse/Attack button attacks; hold to repeat. E interacts or collects nearby loot.
- I opens equipment/inventory. J opens the quest journal. Esc/Menu pauses. Inventory/dialogue pauses combat and hides combat controls.
- Touch controls support dragging the lower-left movement area and tapping targets/Attack; physical mobile-device testing is outstanding.
- Visit Mara at Vigil, take the eastern exit, follow Old Mill Road northeast, defeat both marked mill guards, explicitly collect the flour, then take the southeast exit to Bannerfall and speak to Anja at her bakery. Return to Vigil to bank or trade your loot.
- Click Vigil's protected chest for stash operations; the supply table opens trading. Nearby service tabs permit backpack/stash/supplies access. Select an item to inspect, compare, equip, use, deposit, withdraw or sell. Purchases and sales require an in-game confirmation. Rest restores health.

Backpack: 16 slots. Stash: 40 slots. Tonics stack to five and restore 60 health. Weapon, armor and accessory affect calculated combat stats. Item drops stay on the ground if the backpack is full. Coins are awarded on enemy defeat. Level cap 60; the short quest is designed to reach level 2, not provide a full leveling campaign.

## Saves and recovery

Each new hero gets a new Godot-only slot. Automatic saves follow progression, inventory operations and area changes. Continue returns to the most recent safe camp/town checkpoint. Death pauses and offers safe recovery or title; XP, items, stash, coins, completed encounters and quest claims are retained. Unfinished enemies reset; completed authored guards do not respawn. Wounds/position are not persisted: recovery and Continue heal at the safe checkpoint.

Saves live in Godot's `user://campaigns` directory, normally `%APPDATA%/Godot/app_userdata/Mirrored Dungeon — Godot POC/campaigns`. Primary JSON records use validated temporary writes and last-valid `.bak` copies. Version 1 Pass 04 records migrate to version 2. Invalid files are retained; a valid backup can recover a broken primary. Browser/JavaScript saves are never read or migrated. Copy this whole save directory to back it up. Visible save errors mean progress is still in memory and durability was not guaranteed.

## Documentation and testing

See **PASS05_REPORT.md** for systems, balance, evidence and remaining limitations. **PASS04_REPORT.md** records the preceding checkpoint. **CHANGELOG.md** records changes; **REPOSITORY_STATUS.txt** records the exact working-tree status at delivery.

Current suites: `tests/pass05.gd`, `tests/pass02_contracts.gd`, `tests/pass06.gd`, `tests/pass06_campaign.gd`, and `tests/pass07.gd`. See ART_PRODUCTION_GUIDE.md for asset contracts and tests/pass07-captures for engine-generated visual evidence. Run with Godot `--headless --path godot-poc --script res://tests/pass05.gd --fixed-fps 60` using an isolated APPDATA directory. Engine fixtures are not physical gameplay tests. Desktop JPEG evidence is under `tests/desktop-pass04` and `tests/desktop-pass05`. Historical playthrough tests and one-shot integration scripts have `.txt` suffixes; do not rerun those against this build. Older Pass 01/02 evidence is historical, not current acceptance.

