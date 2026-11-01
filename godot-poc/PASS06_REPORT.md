# Pass 06 — combat implementation and acceptance report

26 October 2026. Current project: `godot-poc/project.godot`, Godot 4.7.2 Standard / Compatibility. The older `MirroredDungeon_Godot_POC` extraction was not edited. This is a playable combat pass with **incomplete desktop acceptance and unfinished character/environment artwork**, not a claim that every requested milestone is done.

## Implemented gameplay

Two abilities per class use a shared data table in `scripts/abilities.gd`, current calculated equipment/level damage, Q/R keys and 210 × 68 combat buttons. One ability command can buffer through an ordinary attack; repeated activation cannot bypass cooldown. Touch press/release is explicitly routed for combat controls. Mouse emulation is enabled for ordinary GUI controls; synthetic world mouse events are ignored to prevent duplicate touch commands. Real touchscreen hardware remains untested.

| Ability | Cooldown | Windup / recovery | Effect |
|---|---:|---:|---|
| Shield Guard | 8 s | 0 / .15 s | 2.5 s, 65% mitigation after equipment defense; shield ring and activation/expiration feedback |
| Cleaving Strike | 5 s | .28 / .34 s | 1.5× damage, 112 px, approximately 215° arc, one hit per victim |
| Arcane Burst | 7 s | .24 / .22 s | 1.6× damage, 135 px radius, .65 s stagger, cover blocks damage |
| Focused Bolt | 4.5 s | .32 / .22 s | 2.4× damage, 410 px, larger projectile, solid-cover collision |
| Evasive Step | 4 s | 0 / .20 s | Facing-directed 720 px/s for .20 s; native collision, approximately 132–144 px travel; no invulnerability |
| Twin Daggers | 3.5 s | .09 / .27 s | Two .95× projectiles, releases .13 s apart, 310 px range, small divergent trajectories |

Walking remains responsive during casts, at reduced speed; dash movement is collision-driven rather than teleportation. Animation playback speed follows ability duration. The existing attack frames remain left/right only.

Menus/dialogue cancel pending ability releases, guard and dash without refunding cooldown. Simulation cooldowns freeze while paused. Travel/death clear transient effects but retain session cooldowns; New Campaign and Continue start with ready abilities at the safe refuge. Cooldowns and temporary effects are deliberately not serialized. No ability unlock data or talent tree was introduced.

Enemy behavior lives in `scripts/enemy_ai.gd`:

| Role | HP | Speed | Damage | Behavior |
|---|---:|---:|---:|---|
| Militia Fighter | 72 | 78 | 9 | .42 s committed melee telegraph, .55 s recovery |
| Archer | 58 | 70 | 10 | .7 s aim windup, cover-aware arrows, preferred 165–270 px spacing, reposition time between shots |
| Shielded Soldier | 72 | 65 | 13 | Frontal hits reduced to 40%; side/rear/recovery exposed; .65 s counter windup, .85 s recovery |
| Raider | 52 | 115 | 7 × 2 | .3 s windup, second attack .18 s later, .9 s recovery |
| Mill Enforcer | 300 | 72 | 20 | Alternating .9 s sweep/lunge telegraphs, collision-aware lunge, frontal defense and 1.2 s vulnerable recovery |

The three existing roaming slots now contain militia, archer and raider. The original captain is a shielded soldier; escort remains militia. The optional Enforcer is southwest of the mill at (2230, 850). Its separate `mill-enforcer-v1` claim grants 45 XP, 15 coins and one padded coat. The original two-member flour ledger and its narrative requirement are unchanged. Killing the elite cannot satisfy the flour objective; leaving it alive cannot block that objective. Its persisted claim prevents respawning or duplicate rewards.

AI retains AStar routes/native collision, bounded home pursuit, idle wandering and distant processing culling. Separation reduces crowd stacking; blocked motion uses bounded deterministic sidesteps and repathing. Return accepts a small home patrol radius so neighbors do not trap one another against an exact point. Stagger interrupts committed attacks; frontal shield blocks do not cancel counters. Enemies stop being valid targets immediately on death.

Target death now clears both the reference and the residual approach path. Continuing a held attack aims at a nearby unobstructed enemy within weapon reach; it does not select a distant chase target. Combat feedback renders above world actors. Role names are separated vertically, projectile/telegraph cues are restrained, and cooldown buttons retain readable backgrounds when disabled.

Loot has stronger pickup glyphs, written rarity, opaque label backgrounds, leader lines and clickable labels. Placement avoids neighboring labels, actors, NPC regions, HUD controls and viewport edges. The bounded layout may omit excess labels in extremely crowded views; ground glyphs and E pickup remain available. New enemy loot finds clear nearby ground. Existing capacity, duplicate-pickup, merchant and stash transactions are preserved.

## Balance and persistence

No Pass 05 class base stats, growth, starting equipment, ordinary/guard rewards, shop prices or flour rewards changed. Ordinary total remains 18 XP/9 coins; guards 40 XP/12 coins; Anja 100 XP/35 coins. All six enemies plus Anja yield 203 XP. The elite's padded coat is an existing modest upgrade, not a new item tier.

The automated full-route controller completed all six enemies with starter gear and normal health/damage: Knight 27.5 simulation seconds / 224.7 HP, Mage 32.0 s / 170 HP, Rogue 28.4 s / 135 HP. Times include approach/travel and are **not isolated time-to-kill measurements or human difficulty ratings**. The controller chooses targets frequently and may use owned tonics below 45% health. Native desktop delays left heroes idle under attack and produced deaths; those are reported rather than used to justify arbitrary stat reductions. Human testing of elite fairness and ranged pressure remains required.

Save schema stays at version 2. The elite uses the existing general claim ledger and ground-drop schema. Existing version-1 migration, version-2 canonical round trips, corruption/backup recovery, interrupted writes, slot isolation, inventory/equipment/stash, currency, quest state, death recovery and full-inventory protection pass. Tests write into dedicated test directories; desktop inspection created additional slots under the redirected validation profile. Original installed-profile saves were copied to the recovery checkpoint and not rewritten.

## Verification

Baseline before changes: 66 Pass 05 checks and 18 contracts, all passed.

Final suites:

| Suite | Result | Scope |
|---|---|---|
| `tests/pass05.gd` | 66 / 0 failures | Prior RPG, save migration/recovery, economy and integrated quest regressions |
| `tests/pass02_contracts.gd` | 18 / 0 failures | Collision, buffering, pause, touch movement, population and cover |
| `tests/pass06.gd` | 52 / 0 failures | Abilities, mitigation, timing, multi-hit, native dash collision, projectiles, shield facing, archer retreat/LOS, separation, return, elite patterns/rewards, target invalidation, touch ability, loot labels |
| `tests/pass06_campaign.gd` | 30 / 0 failures | All-class complete walking/combat/flour/Anja/Vigil/Continue routes |
| Graphical `pass06.gd` | 52 / 0 failures | Same combat suite with actual renderer, unaltered viewport PNG captures |

There are **166 distinct automated assertions** across four suites; the graphical rerun is not counted again. The Pass 05 fixture excludes the new optional elite when asserting the old quest's 158 XP total. The contracts count ordinary/quest actors separately from the elite. Their old sources are preserved in the checkpoint. The full-route suite uses normal attacks, not injected damage or invulnerability; it still drives engine APIs and can select offscreen targets, so it is not desktop acceptance. The focused combat suite relocates fixtures and directly damages actors for specific ledger/mitigation assertions.

Final logs are `tests/pass06-final-*.txt`, `pass06-render.txt`, `pass06-render-errors.txt`, and `pass06-import.txt`. Pass 05 intentionally induces a blocked-write ERROR to check save failure handling; it is not an unexpected runtime failure.

## Actual Windows inspection

Computer Use (`@oai/sky`, native mouse/keyboard) launched the current workspace project at normal speed, separate from the user's already-open older game. That older game/editor was left untouched. The inspection used a redirected validation APPDATA profile and additional New Campaign slots.

- **Mage:** New Campaign, Mara, camp exit, scrolling travel, ordinary combat, Arcane Burst and Focused Bolt activation, all three roamers defeated across attempts, loot pickup, death/recovery, and an attempted Enforcer fight. The hero died at the elite. Mill guards, flour, Anja, return and restart/Continue were not completed through desktop input in this pass.
- **Rogue:** New Campaign, both abilities activated, Mara, camp exit, ordinary targeted dagger combat, militia/archer rewards, Twin Daggers against Raider, death and protected recovery. Full quest and elite desktop acceptance remain incomplete.
- **Knight:** New Campaign and native Q/R activation, visible guard ring/notification and cooldown states. Knight normal/elite combat was exercised by scripted suites, not completed as a native desktop run this pass.

Saved native captures: `tests/desktop-pass06/knight-guard.jpg`, `rogue-step.jpg`, `rogue-combat.jpg`, `rogue-recovery.jpg`, `mage-defeat.jpg`. These are unaltered Computer Use captures. Some show intermediate UI before the final animation/touch refinements. Short effects often expired before the desktop capture completed; the precise ability/projectile frames are in the explicitly engine-driven `tests/pass06-captures/` PNGs. Do not mislabel those as desktop input evidence.

Graphical review found and corrected faint disabled buttons, overlapping enemy names, feedback drawn behind actors, and loot labels colliding with the hero/HUD. Final rendering was re-inspected. Audio was not formally evaluated. No physical iPhone or touchscreen acceptance, prolonged farming test, or low-end performance benchmark is claimed. AI is bounded to six active actors in this slice, with distant culling and .65 s repath intervals; saved farming history can still grow.

## Art requirements and remaining work

1. **Highest acceptance priority:** complete native Mage/Rogue flour-to-Anja-to-Vigil-and-restart runs; complete native Knight ability/group/elite combat. Exercise strafing, rapidly moving targets and touch controls on hardware. Preserve the current validation saves for continuation or create separate named slots.
2. **Enemy art:** all five roles reuse the existing 56 × 64 enemy sprite (foot origin 28,64). Names, defense arcs and telegraphs communicate behavior, but this is not finished distinct archer/shield/raider/officer artwork. Supply matching directional silhouettes, weapons and windup/recovery/death frames. No procedural shape is claimed as a completed character sprite.
3. **Hero directional attacks:** supply up, down, northeast, northwest, southeast and southwest for each class: eight frames per direction, 160 × 128 RGBA canvas, foot origin (80,112). Existing normal playback is .32 s at 25 fps, impact .16 s Knight/Mage and .12 s Rogue; ability playback scales to the timing table. Keep weapon/projectile direction aligned to these release frames. Total missing: 144 directional attack frames, plus dedicated ability/guard poses if authored.
4. **Environment:** prior geometric trees and fortress-like civilian buildings remain provisional. No image-generation retries or source-art modifications were made.
5. **Further polish:** test very large loot piles, extreme viewport sizes, mobile portrait layouts, long-session save growth, all obstacles and all directional animation transitions. This pass retains the landscape layout. Enemy HP bars are compact and can still cluster in very tight crowds. Ability cooldowns reset on Continue as documented; persist them only if later design requires it.

## Preservation and continuation

Recovery source checkpoint: `../checkpoints/pre-pass06-20261026-104223/` contains original scripts, scenes, tests, project configuration, original installed-profile campaigns, initial Git status and hashes. Prior archives/checkpoints remain intact. All 567 files in the original preservation manifest, including JavaScript and source artwork, match SHA-256 exactly. A separate 117-file root code/data snapshot also matches.

Branch remains `main`, HEAD `477ae70194e2b5b1cfe7814b2b724c11bd30cfa6`. No commits, resets, branch switches, pushes or deployments. The repository already had 28 modified tracked files; none was altered by this pass. Godot remains an untracked directory at the repository level. Exact final status is recorded in `PASS06_GIT_STATUS.txt`; test evidence in `tests/pass06-preservation.json`.

Implementation changes: `scripts/main.gd`, `actor.gd`, `interface.gd`, `project.godot`; new `abilities.gd`, `enemy_ai.gd`, `combat_overlay.gd`; two adjusted regression fixtures, two new suites, evidence and documentation. `campaign.gd`, `items.gd`, authored scene geometry and all source assets are unchanged.

Next continuation: open this project's `project.godot`, use New Campaign or the preserved validation slots, and complete the desktop acceptance items above before calling Pass 06 fully accepted.
