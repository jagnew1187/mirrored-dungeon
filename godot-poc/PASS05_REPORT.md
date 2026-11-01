# Pass 05 — RPG systems and integration

Implemented 26 October 2026 after the Pass 04 checkpoint. The actual starting project was Pass 02; Pass 03 artwork was not complete. Development stayed inside the Godot project, with additional checkpoints and validation outputs outside it. The JavaScript preservation manifest still matches all 567 original files. No commits, resets, branch switches, pushes, hosting or web exports were performed.

## Implemented

Stable data-driven items cover class weapons, armor, accessories and stackable tonics. Item records include ID, category, class restrictions, rarity, description, value and modifiers. Equipment, level growth and transient modifiers feed a single clamped calculation used by combat. Item inspection compares against equipped gear. Backpack capacity is 16, stash capacity 40 and tonic stack size 5. Transfers move one unit atomically; full containers preserve the source. Ground drops persist, require pickup, and remain if storage is full.

Vigil's supplies table provides class-filtered purchases, and owned backpack items can be sold near camp services. Prices and confirmation appear before exchange. Transactions validate ownership, space, funds and revision; stale confirmation callbacks cannot duplicate an operation. No salvage/crafting system was added.

Each hero has an independent version 2 JSON slot containing name, class, XP, coins, inventory, equipment, stash, quest state, claimed rewards, authored encounter deaths, roaming population state, ground loot and safe checkpoint. New Campaign never reuses the active slot. Continue returns safely to camp/town with restored health. Death keeps progression/items and explicitly offers recovery or title. Incomplete fights reset; authored defeats and once-only reward ledgers persist.

Writes flush a temporary record, validate it, preserve the last valid primary as backup and rename into place. Corrupt primaries can recover from backups; invalid originals are retained. Version 1 Pass 04 records migrate without accessing JavaScript storage. Interrupted temporary files do not supersede valid records. Failed writes display a warning; they do not promise saved progress.

Inventory, dialogue and trade screens pause gameplay, hide attack controls and use large buttons with three-item pages. Optional hero names, distinct slot labels, an objective line and J journal support the existing three-area quest. A visible supply crate now marks flour recovery. Existing artwork was reused.

## Balance and adjustment points

| Setting | Knight | Mage | Rogue |
|---|---:|---:|---:|
| Starting health | 270 | 200 | 165 |
| Damage | 34 | 23 | 19 |
| Attack cooldown seconds | .53 | .60 | .37 |
| Speed pixels/second | 204 | 225 | 280 |
| Range pixels | 85 | 315 | 270 |
| Health per level | 12 | 8 | 8 |
| Damage per level | 2 | 2.5 | 1.5 |
| Starting defense | 2 | 0 | 0 |

`campaign.gd` contains BASE/GROWTH, increasing XP thresholds `80 + 40*(level-1)^2`, cap 60, and stat clamps. `items.gd` contains inventory capacities, gear, tonic healing description, shop and deterministic rotating drop pool. `main.gd` contains actual tonic healing (60), kill rewards, enemy windup (.38s), drop positions and live combat. Keep tonic description and behavior in sync when tuning.

Ordinary enemies grant 6 XP/3 coins; each mill guard grants 20 XP/6 coins. Anja grants 100 XP/35 coins and a keepsake once. Five kills plus the quest total 158 XP: level 2 with 78/120 toward level 3. Starting currency is 30. Purchases cost twice item value; selling returns value. Captain upgrades grant +4 damage for Knight/Mage, +3 damage and -.02s cooldown for Rogue. Padded coat adds 12 health and 1 defense. Keepsake adds 16 health; clasp adds 8 speed. Rarity is Common or Improved. This is a modest early-game economy, not a balanced 60-level campaign.

## Automated verification

Godot 4.7.2 Standard, Compatibility renderer. `tests/pass05.gd`: **66 checks, zero failures**. It covers XP idempotency, growth/cap, actual attack releases for each class, live equipment damage, quest integration, UI bounds, hidden combat controls, stale transfers, capacity/stack rules, buy/sell validation, ground-loot duplication, protected recovery, class-slot isolation, version migration and save integrity. Remaining enemy deaths in the integrated fixture use direct damage; this is not a normal-speed playthrough.

Save tests include exact canonical round trips, corrupt-primary backup recovery, interrupted temporary writes, preserving valid backup when primary is broken, invalid item/class rejection, both copies corrupt, and blocked filesystem writes. The log's directory-creation ERROR is deliberately induced by the blocked-write test; that check passes and verifies the original file survives. This is distinct from an unexpected runtime error.

The existing `pass02_contracts.gd` also passes **18 checks, zero failures**, including touch input translation and projectile collision against cover. These are engine-injected tests, not physical touchscreen tests. Historical Pass 04 tests passed 36 checks before Pass 05 replaced their minimal equipment model. Historical sources are retained with `.txt` suffixes.

## Actual Windows gameplay evidence

Computer Use operated Godot's Windows project manager/editor and the graphical game with native mouse/keyboard actions at 1.0x speed. The project was this workspace's `godot-poc`, not the old extracted POC. Screenshots are unaltered JPEG captures in `tests/desktop-pass04` and `tests/desktop-pass05`.

Knight: new campaign, Mara introduction, road departure/camera scrolling, three ordinary enemies and both mill guards defeated by click targeting, natural loot pickup, coat and clasp equipment, tonic consumption, explicit flour recovery, Bannerfall delivery, level 2, keepsake pickup, sword upgrade and return to Vigil through the normal menu. Buying clasp reduced coins 30 to 6; its speed changed 204 to 212. The coat increased maximum health by 12 and defense by 1; tonic restored exactly 60. Quest reward changed total XP to 158 and coins to 62; sword raised level-2 damage 36 to 40. Selling a spare coat increased coins 62 to 67 and removed one item. A banked tonic survived stopping/restarting the game and Continue, then withdrew correctly after the quest. Death/recovery was observed earlier during idle road inspection.

Mage: selected a fresh campaign, spoke to Mara, walked out, observed death/recovery after standing among enemies, then returned and defeated all three ordinary enemies using targeted arcane bolts. A visible projectile is captured in `mage-projectile.jpg`. Reached the mill with the final visible flour crate, but died during the guard encounter after desktop-tool delays; `mage-defeat.jpg` records the explicit recovery/title choices.

Rogue: fresh selection, Mara introduction, camp departure, scrolling movement and all three ordinary enemies defeated by targeted thrown daggers. `rogue-camp.jpg`, `rogue-attack.jpg` and `rogue-projectile.jpg` capture the actual class and attack.

**Desktop coverage remains incomplete:** the full mill-to-Anja-to-camp loop was completed only for Knight. Mage/Rogue full quest completion, Rogue death/recovery and exhaustive per-class directional/collision checks were not completed through Computer Use. Automated integration passes for all three do not close that acceptance gap.

Evidence highlights: `main-menu.jpg`, `knight-combat.jpg`, `earned-loot.jpg`, `mill-patrol-cleared.jpg`, `flour-recovered.jpg`, `bannerfall.jpg`, `anja-delivery.jpg`, `quest-level-two.jpg`, `upgraded-knight.jpg`, `stash-restored.jpg`, `sale-complete.jpg`. `stash.jpg` intentionally preserves the initial panel-background defect; `stash-restored.jpg` shows the correction. Some earlier screenshots precede the final current/max-HP text, slot-label and flour-crate changes.

## Remaining defects and limits

- High visual priority: repeated flat geometric trees and fortress-like civilian buildings still read as placeholders. Replace with authored woodland/civilian art, then retune footprints and paths. Pass 03 visual acceptance is not claimed.
- Animation priority: attacks reuse left/right artwork for all aim directions, while walking has eight views. Add matching directional attack frames; current melee hit direction and projectile travel are functional but presentation is incomplete.
- UI polish: ground-loot and NPC labels can overlap near Anja or clustered drops. Offset/stack labels and provide stronger pickup silhouettes. The final flour crate was seen during the Mage mill attempt; earlier Knight screenshots predate it. Widened labels have engine validation but no exhaustive desktop inspection.
- Balance: click targeting attacks a chosen enemy; it does not automatically select another when one dies. Standing idle among several attackers is dangerous, especially for Mage/Rogue. Desktop tool delays are not representative reaction times. The three-enemy opening needs broader human playtesting before tuning difficulty.
- Performance: items use data records rather than persistent item nodes; UI reuses a small set of rows. No formal frame-time, memory, long-session or low-end-device benchmark was performed. Ground-loot/claim history can grow over repeated farming.
- Physical iPhone/touchscreen, audio acceptance, long sessions, every obstacle and every directional animation have not been exhaustively inspected. The available Computer Use API does not support short animation recordings; screenshots are provided instead.
- Only the existing three-area campaign slice is implemented. No expanded act, Arena, Endless, companion AI, networking, crafting or deployment was added.

Current screenshots and test results are evidence of specific behavior, not a claim that the environment is visually polished.
