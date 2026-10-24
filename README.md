# Mirrored Dungeon — Strategic Gauntlets 0.6

Open `index.html` in a browser. The updated game remains a self-contained HTML file with its original embedded character and boss sprite sheets. No service, asset download, or API key is required to play.

For an HTTP preview, run `npm start` and open `http://127.0.0.1:4173`. The optional server uses only Node.js built-ins and serves this game on the local computer.

## What changed

All three bosses now have scrolling themed gauntlets. The main passage leads directly north to the boss. A separate guarded side passage branches east and requires extra travel, combat, and a return to the main passage. Physical walls separate the routes; generated layouts are validated for access to the entrance, boss gate, and reward shrine. There are no countdown gates or timed reward seals.

At the fork, three seeded reward choices are visible before commitment. Every card shows the name, pixel icon, green benefit, red drawback, and exact percentages/durations or charges. Combat drawbacks start at boss entry; the healing crystal explicitly states that its cost is the guarded detour. Tap a card for full details. Continuing along the main passage never requires opening a selection screen. Clearing the optional guards unlocks exactly those same three choices; choose one or decline while the race clock continues.

| Reward | Current configurable effect |
| --- | --- |
| Berserker's Edge | +25% outgoing damage and +20% damage received for the first 15 boss seconds |
| Guardian's Ward | Reduce the next boss hit of at least 9 raw damage by 70%; −12% movement speed for the first 10 boss seconds, even if the charge is spent |
| Restoration Crystal | Immediately restore 30% maximum health, capped at maximum; guarded detour only, no combat penalty |
| Temporal Surge | 25% shorter cooldowns and 15% slower basic attack speed for the first 15 boss seconds |

Pending, active, consumed, and expired reward states prevent stacking and repeat collection. Boss-duration rewards start at boss entry. Unused rewards expire at encounter completion, and restarting clears the current reward and preview state.

Pyromancer rooms contain fire vents, burning floor tiles, hounds and a guarded shrine. Necromancer rooms contain skeletons, cursed slowing runes and a priority-target summoner. Warlord rooms contain fortifications, breakable wood, armored guards and warned charges. Rival victories add controlled hazards or reinforcements to the corresponding gauntlet. Every trap has warning, active and recovery states. The main passage retains room to dodge.

Solid cover blocks projectiles and targeting, including Shadowstep through a wall. Enemies use cached grid paths and optional guards remain in their wing when the player takes the direct route. The Knight can break nearby wooden cover through its normal auto attack.

## Competition

Both mirrors generate rooms and reward offerings from the same seed and use the selected class. The rival chooses direct or reward routes based on seeded preferences, health, known rewards and boss empowerment. It pays traversal and guard-combat costs, collects only an offered reward, carries temporary rewards as pending on the return trip, then activates them at boss entry. Bosses lose health through class attacks and abilities; there is no arbitrary boss-clear timer or automatic assistance based on who is losing.

The rival is still an analytic strategy/combat simulation, not a second physically rendered character. Its traversal and combat estimates use the shared room, route geometry, class statistics and configurable attack uptime/dodge behavior. It does not replay every physical player collision. Multiplayer networking remains unimplemented.

## Files and build

| File | Responsibility |
| --- | --- |
| `index.html` | Playable game, original assets/combat, scrolling/input integration and embedded update |
| `world.js` | Seeded scrolling rooms, routes, navigation, hazards, inheritance and environment configuration |
| `rewards.js` | Configurable reward descriptions, pre-commitment preview, claiming and mobile UI |
| `rival.js` | Seeded rival strategy, traversal costs, reward lifecycle and combat simulation |
| `telemetry.js` | Local match history and sample-gated balance analysis |
| `graphics.js` | Procedural pixel assets, themed floor/wall rendering, traps, reward icons and enemy accents |
| `integrate.cjs` | Embeds those five sources into the existing HTML game |
| `serve.cjs`, `package.json`, `.gitignore` | Local preview, build/test commands and generated-file exclusions |
| `test-game.cjs`, `test-strategy.js`, `test-risk.js`, `test-mobile.cjs` | Browser integration, actual route traversal, rival, lifecycle and responsive tests |
| `BALANCE.md` | Measured route results, testing limits and balancing recommendations |

After editing a source module, run `npm run build` and commit both the source and `index.html`. Core combat integration hooks remain in the original inline script. The embedded character/boss sprites, frame dimensions, animation sequences and isolated frame padding are preserved. A duplicate enrage damage increment was removed so the player's boss and simulated rival boss apply the same single +5 empowered melee increment.

All new graphics use the existing Canvas pipeline and palette, including pixel warning badges and animated active-penalty chevrons: themed stone floors and masonry, pillars, rubble, broken walls, wooden barricades/destruction debris, trap activation/warning frames, magical runes, four reward icons, a three-choice shrine, entry/exit and optional-route markers, pickup rings, armor shields, charge warnings, summoner marks and fire accents. No external art packs were introduced.

## Development settings and telemetry

`window.MirroredDungeonDebug.config` exposes the seed, world height, detour depth, difficulty, enemy/guard counts, guard health, obstacle density, hazard frequency/damage/interval, all four reward values and rival skill settings. Change these before starting a match. Reward values are grouped under `config.rewards`. Use positive frequency, world dimensions and combat values.

`MirroredDungeonDebug.state().stats` records selected class, gauntlet time, chosen route, reward exposures/selections, time to collect, complete detour time, boss duration, damage, deaths, completion time and outcome. Rival encounter records include route, offered choices, claimed reward and combat time. The last 50 matches are stored in browser localStorage where available, with an in-memory fallback. Nothing is uploaded.

`MirroredDungeonDebug.history()` returns that history. `MirroredDungeonDebug.balanceReport()` flags nearly universal or rare reward claims and slower reward detours after sufficient samples. Comparisons group class, boss, empowerment, seed and tuning, and include gauntlet plus boss time. Each comparison reports extra gauntlet seconds, boss seconds saved, net seconds/percentage, whether the detour helps or hurts successful completion time, and completion rates. Version 3 history separates the new tradeoffs from old reward tuning. They are observational and do not automatically change combat statistics or grant catch-up power.

## Validation

Install Node.js, run `npm install`, then `npx playwright install chromium`. Run `npm test`. Alternatively set `CHROME_PATH` to an installed Chromium browser. The test runner also supports the bundled Codex Playwright runtime when available.

The latest run passed 920 counted checks. Tests include 36 actual route traversals (three classes × three bosses × both routes × desktop/mobile), 20 generation seeds per boss per primary viewport, visible pre-commitment reward values, unchanged claim options, touch claiming/declining, ongoing timers, all buff effects/lifecycles, healing caps, resets, collisions, hazards, inheritance, full rival progression, telemetry and sample thresholds. Extra viewport checks cover 320×568 portrait and 844×390 landscape, visible ability buttons and touch movement with letterboxing. Preview PNGs and raw `test-results.json` are generated locally and ignored by Git.

Chromium tests and visual checks are complete. Physical iPhone Safari testing, human class win-rate testing, and statistically meaningful reward-payoff testing have not been performed. See `BALANCE.md` before treating provisional values as final balance.

GitHub repository: https://github.com/jagnew1187/mirrored-dungeon. The project tracks the main branch.
