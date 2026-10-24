# Mirrored Dungeon — Strategic Gauntlets 0.6

## Environment path update

### Campsite floor and buff artwork

Heroes' Camp now uses detailed grass, packed earth, rustic cobblestone and forest-litter materials from `assets/camp-materials-v1.png`. The ground is composed once into a cached camp canvas. Buffs use higher-detail sword/shield/crystal/hourglass sprites in 80px UI canvases and on the reward shrine. Active and spent shrine artwork replaces the plain rectangular altar. The atlas is embedded for offline play; exact benefits, costs and durations remain unchanged and visible. `assets/camp-buffs-v1.md` records the generation and transparency-cleanup prompts. `test-camp-buffs.cjs` checks all four distinct icons, high-density canvases, unchanged config/masks, exact reward copy and touch/mouse claiming.

### Narrative cues, entrances and heroes' camp

`journey.js` replaces painted `BOSS` and `GUARDED` floor text with a wounded scout giving a themed plea and directions, worn tracks along the main route, and a supply-cache cue on the eastern detour. Reward previews still show exact benefits, drawbacks and durations before commitment. Dialogue and collection never pause the race.

The north gate is now an open royal archway for Warlord, a crypt doorway for Necromancer, and carved volcanic pillars for Pyromancer. Two explicit side-post masks block the architectural supports while the central opening retains the existing immediate boss transition. Sprite opacity is never a collision source.

The selection/waiting room is now Heroes' Camp, with seeded earth/grass, tents, campfire/cooking pot, bedrolls, supply table and the other two playable classes resting nearby. Camp props and companions are cosmetic; existing race, wave, health and boss-order mechanics remain intact. `assets/journey-v1.md` records the prompt and integration details. `test-journey.cjs` checks camp labeling and all three entrance transitions/geometry on desktop and mobile, with generated camp and entrance screenshots.

### Pyromancer environment update

The Lava Cave and Fire Sanctuary now use `pyro.js` and embedded higher-detail volcanic material/prop atlases. The cave features rough basalt, carved volcanic walls, a copper-inlaid processional path, obsidian formations, altars, flame sconces and breakable charred barriers. The sanctuary has polished obsidian floors, ritual rings, a fire altar, braziers and four solid cover pillars. Ring markings and background ember cracks are decorative; hazards remain explicit game entities.

Both fire vents and burning-floor hazards have cold, warning and active sprites with colored outlines and no `!` marker. Original damage intervals, timing and hit radius remain unchanged, along with boss abilities, inherited powers, rewards, route choices, competitive timers and seeded rival progression. Source art/prompts are in `assets/pyro-materials-v1.png`, `assets/pyro-props-v1.png` and `assets/pyro-art-v1.md`. The Warlord and Necromancer environments retain their implementations.

`test-pyro.cjs` verifies all classes, deterministic room equivalence, mask preservation, reward lifecycle, boss transitions, real combat damage, projectile cover, physical boss navigation, active/recovery vent behavior, destroyed barrier passability and cleanup. Existing route and mobile tests cover the complete build. Physical iPhone Safari and human play-feel/balance testing remain outstanding.

### Necromancer environment update

The Halls of the Dead and Crypt now use dedicated higher-detail burial floors, funerary masonry, an engraved jade-inlaid ceremonial path, sarcophagi, hooded statues, crypt pillars, skull sconces with ghost light, candle altars, bone debris and breakable coffins. Rune traps have dormant, awakening and active sprite states with visible outlines and no `!` marker. Their existing slow, timing and radius are preserved. Coffin damage/debris states use the existing breakable collision system. `necro.js` defines the art and extra explicit prop masks; pixels never determine collisions.

The direct/reward fork, offered rewards, numerical tradeoffs, running timer, summoners and inheritance remain operational. The crypt has four solid pillars with open space around each; targeting, shots and enemy navigation use the existing cover system. Both mirrors generate the same seeded room. Warlord and Pyromancer environment behavior is unchanged by this update.

Source art and prompts are in `assets/necro-materials-v1.png`, `assets/necro-props-v1.png`, and `assets/necro-art-v1.md`. The build embeds both atlases for offline play. Run `node test-necro.cjs` for the 48 new checks covering each class, deterministic geometry, mask preservation, rewards, boss transition/damage, crypt cover and physical boss navigation, curse states, broken-coffin passability, victory and restart. Existing full-route desktop/mobile and rival tests also pass. Physical iPhone Safari and human balance evaluation remain untested; the rival remains the existing analytic simulation.

### Warlord vertical slice

Sconces, braziers, throne and dais, banners, weapon racks, training dummies, and wall shields now use the matching `assets/warlord-decor-v1.png` atlas. `warlord-decor.js` caches scaled sprites and a warm light texture, then flickers light opacity. Throne-room layout, prop collision, and combat remain unchanged. Sampling bounds isolate the broad dais and rack to avoid neighboring sprite fragments. The source prompt is in `assets/warlord-decor-v1.md`.

Warlord traps and barriers now use `assets/warlord-props-v1.png`: retracted/emerging/extended spike plates, intact/cracked/broken barricades, reinforced crates, iron-bound barrels, and stone cover. Warning outlines and the warning exclamation remain visible; artwork follows existing trap timing and HP without changing collision. Scaled sprite cells are cached and embedded for offline play. `assets/warlord-props-v1.md` records the generation prompt. The Warlord test also captures `warlord-traps-barriers-preview.png` and checks rendering preserves masks and destroyed barriers remain passable.

Higher-detail materials are now integrated from `assets/warlord-materials-v1.png`: two stone floors, masonry, and patterned red carpet. The atlas is embedded by the build, sampled with smoothing disabled, and rendered into cached floor canvases. `assets/warlord-materials-v1.md` records the generation prompt and integration details. No gameplay geometry changed in this art pass.

`warlord.js` now owns reusable stone floor tiles, fortified border walls, animated torches, banners, racks, shields, dummies, breakable crates/barrels/barricades, defensive approach lanes, and a raised throne/carpet/brazier arena. Armory props have independent rectangular collision masks. Four throne-room pillars provide solid tactical cover, block projectiles and targeting, and leave open paths around every side. Existing enemy grid navigation and collision resolution apply in the arena. Boss behavior and inherited powers are preserved.

Warlord always offers Edge, Ward, and Surge; only one can be collected. `DEV.warlord.edge` configures its +30% outgoing damage / +20% incoming damage for 15 seconds at boss start. Other dungeons retain their existing reward settings. Both player and simulated rival use the same Warlord configuration, seeded geometry, and options. Claimed reward values are snapshotted so the rival uses its own encounter's tuning independently of the player's active dungeon. The timer keeps running during claim/decline.

This pass changes only Warlord environment behavior. The actual supplied Armory/Throne reference images still were not accessible; current Warlord artwork is authored procedural pixel art. It cannot yet be certified as matching those references. Cached tiles and small per-frame torch updates keep drawing lightweight; original sprite frame isolation remains unchanged.

Run `node test-game.cjs`, `node test-environments.cjs`, and `node test-warlord.cjs` with `CHROME_PATH` set if necessary. The Warlord suite adds 46 checks for class access, deterministic rooms, precommitment values, real damage scaling, pending/expired effects, large enemy depenetration and physical boss navigation around cover, victory cleanup and restart. The rival remains an analytic simulation rather than physical path replay. Physical iPhone Safari and human balance/play-feel evaluation remain outstanding.

The self-contained build now maps Warlord Armory → Throne Room, Pyromancer Lava Cave → Fire Sanctuary, and Necromancer Halls of the Dead → Crypt. `environments.js` supplies six cached procedural Canvas scenes, with racks/banners/throne, basalt/molten fissures/ritual rings, and burial niches/sarcophagus respectively. Existing direct and guarded reward routes, visible numerical tradeoffs, combat, and safe-area touch controls are preserved.

The six requested reference images were not present in the repository or accessible conversation attachments. These scenes are procedural substitutes, not adaptations of those missing images. Supply the images for a subsequent reference-art pass.

Collision remains exclusively the explicit `world.js` rectangle mask (`room.obstacles`), never image opacity or decorative pixels. Arena dressing is non-solid to preserve existing combat space. Route generation reserves walking spines and validates entrance-to-exit and entrance-to-reward connectivity. Rendering does not modify masks.

Validation for this update: 920 existing checks passed in installed Chrome, including 36 physical route traversals and portrait/landscape touch checks; 19 additional checks cover six distinct scene outputs, unchanged masks, clear spawn points, and boss transitions. Six `*-gauntlet-preview.png` / `*-arena-preview.png` files are generated by `test-environments.cjs`. Physical iPhone Safari remains untested. On systems without a Playwright browser, set `CHROME_PATH` to the installed Chrome executable before `npm test`.

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
