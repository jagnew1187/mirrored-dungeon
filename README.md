# Mirrored Dungeon — Strategic Gauntlets 0.6

Open `index.html` with the `runtime-assets/` folder beside it for offline play, or run `node serve.cjs` for the local preview. Keep that folder with the HTML when copying the build. `node integrate.cjs` rebuilds these bundles from the source assets. Artwork is split into local JavaScript bundles so no published file exceeds GitHub's per-file limit. Animation review pages remain self-contained.

## Practice lobby

Enter the heroes’ camp to practice movement, attacks, jumps and skills against
recurring mobs alongside the other heroes. The match countdown and rival stay
stopped. Falling in practice restores your health. Choose a first boss (Start
match on mobile) to begin a fresh race: health, cooldowns, kills and practice
effects reset, and the 210-second countdown and simulated rival start together.
Returning to camp between bosses during a match keeps the timer running.

The right-hand tent is a square canvas pavilion. The lobby's shared kill counter
includes companion kills. **+ Spawn wave** adds up to four mobs, with a cap of
12 active enemies. Automatic practice waves continue; kills and wave controls
reset on restart and disappear when a fresh competitive match begins.

## Sound and atmosphere

Open **Sound · music & effects** below the battlefield to set overall, ambience,
music and effects volume, or press **M** to mute. Settings persist locally. Audio unlocks
on a tap or keypress, pauses with the game and suspends when the tab is hidden.
Music and ambient beds use an original procedural Web Audio score. Combat uses
clean CC0 Foley samples and restrained spell textures, bundled for offline play.
See `assets/audio/CREDITS.md` for sources and rebuild instructions. Camp has woodland air, fire crackle and sparse
melody; armory, crypt and lava cave have distinct drones and textures. Boss rooms
crossfade to separate marching, hollow and driving musical themes.

Combat effects follow actual attack releases, successful casts and collisions:
Knight sword/cleave/shield sounds, Rogue dagger throws and shadow/smoke effects,
Mage arcane/fire/frost/healing sounds, enemy swings/bites, boss slams and summons.
Impacts distinguish flesh, metal, wood, stone and magic. Broken cover cracks once;
misses keep the swing/release sound without inventing a hit. Offscreen culling,
distance attenuation, per-effect throttling and a shared voice limit keep busy
practice waves from overwhelming the mix. Effects volume also controls footsteps.
The v2 bank adds 62 variants, natural transients and restrained stereo positioning.
Cues play dry at their original pitch, with isolated buffers and an eight-cue overlap
cap to keep fights clear. Mono PCM is decoded
once and shared across rooms; the procedural cues remain a decoding fallback.

Footsteps follow actual travel and floor material, with a light Knight armor
rattle. Boss arrival captions and musical stingers briefly duck the ambience
without pausing movement or the race. Embers, dust motes, cloth ripples and
breakage debris are decorative only and respect reduced-motion settings.

## Manual combat controls prototype

Jump has directional takeoff, airborne leg poses and a brief landing settle with
dust, using the existing hero artwork. Spikes, burning floor tiles and slowing
runes are avoided while sufficiently airborne; flame jets, enemy attacks and
projectiles still hit. Damage flashes include pixel impact flecks (orange for
fire traps), and active rune slows show ankle links and an hourglass. These
indicators follow actual damage and slow timers.

Basic attacks now resolve at the authored contact/release frame: 0.16 seconds
for Knight/Mage and 0.12 seconds for Rogue. Melee checks range and cover again
at impact. Enemy contact attacks have a 0.2-second windup with a small amber
cue; moving away before impact avoids the hit. Boss special abilities retain
their existing telegraphs and behavior. Repeated clicks cycle overlapping
enemies, starting with the frontmost, and a pointer above the target stays clear
of its sprite.

Spikes deal 7 immediate damage at default difficulty. Fire traps apply one
non-stacking burn: four ticks totaling the same 7 damage over two seconds.
Continued exposure refreshes its duration without postponing ticks. Runes slow
movement by 25% for 0.8 seconds, refreshing without stacking. Jumping avoids new
effects from ground traps; it does not extinguish an existing burn. Trap tuning
is configurable in `DEV.traps` and recorded with balance telemetry.

On desktop, **left click an enemy** to select it, approach and automatically repeat attacks while in range and line of sight. Release does not cancel this selected-target command. A ring marks the selected enemy. **Click the ground** to cancel selection and move without attacking. Defeating the target stops attacks instead of selecting another enemy. Pause, blur and restart also clear selection. Right mouse is ignored; touch dragging remains movement-only. Attack/J retain their independent tap/hold behavior. `test-mouse-controls.cjs` checks all classes, target approach/range/death, cover, ground cancellation and touch isolation.

Basic attacks require input: tap **Attack** / **J** once, or hold to repeat at the selected class's existing attack rate. A nearby visible enemy is targeted automatically; Mage and Rogue can also fire in their last movement direction with no target. Knight can swing at nearby destructible cover. Walking no longer hides a basic attack animation. The three class abilities remain on buttons and keys **1 / 2 / 3**; camp companions and enemies retain automatic combat.

**Jump** / **Space** performs a 0.46-second hop with a 1.25-second cooldown. During the raised portion it clears spikes, burning floor tiles and curse runes. Flame jets, enemy attacks, boss attacks and projectiles still hit. Solid walls/cover, movement speed and the competitive clock remain in effect. All three classes share the jump tuning (`PLAYER_ACTIONS` in `manual-controls.js`). The hop uses directional poses with takeoff/landing compression. Balance history includes impact delays, trap values and enemy windup tuning. The simulated rival is unchanged; human balance testing and physical iPhone Safari testing remain outstanding.

Attack and Jump sit inside the arena, clear of the movement joystick and original skill bar at 320px portrait and landscape sizes. Pointer capture supports holding Attack while moving and jumping; cancellation, blur, pause and restart release held input. `test-manual-controls.cjs` exercises actual keyboard/button input and three simultaneous touch points in addition to damage, cooldown, hazard and collision checks. Rebuild with `node integrate.cjs`.

## Environment path update

### Wizard and Rogue movement

Wizard (the Mage class) and Rogue now have eight authored walking directions, including four 45-degree views, with eight walking poses and a dedicated planted standing pose per view. They use the same angular overlap and actual-displacement direction selection as Knight. Stopping preserves facing and phase. `HERO_WALK_STRIDES` configures full-cycle distance (Mage 84px, Rogue 92px); travel speed, combat damage/cooldowns, collision, skills, race timing and Knight artwork remain unchanged. Attacks and skills retain their previous side-view artwork.

Open `heroes-walk-review.html` for class/view selection, standing, pause and frame stepping; regenerate it with `node make-class-preview.cjs`. `assets/class-gait-art.json` lists all source sheets. `prepare-class-gaits.py` derives `assets/class-gait-frames-v2.json`, registering the Mage at his hood instead of the staff crystal and separating boot contact from staff tips. `class-gait-renderer.js` caches approximately 2x game-resolution atlases with nearest-neighbor sampling, then releases source image references. Source PNGs are preserved. `test-class-gaits.cjs` checks all directions and standing poses, source/cached bounds, scale, normalized speed, phase, reduced-motion animation, no mirroring, cache size and preview controls on desktop/mobile layouts. Generation prompts and visual corrections are in `assets/class-gaits-v2.md`.
### Knight walking and standing update

Knight now has eight walking poses in each of eight directions, with matching planted standing poses and separately authored left/right equipment views. Movement selects the view from actual displacement; diagonal input selects dedicated 45-degree views, with a five-degree sector overlap to prevent flicker. `combat.js` exposes `KNIGHT_WALK_STRIDE` (88 world pixels per full two-step cycle), replacing accumulated animation slowdowns for Knight only. Travel speed, collision, combat, race timers and Mage/Rogue playback are unchanged. Idle retains the last movement direction. Attacks/skills retain the existing side-view sheets.

Open `knight-walk-review.html` to inspect game-size and enlarged cycles, pause, stand or step through poses. Rebuild the preview with `node make-knight-preview.cjs`. Cardinal assets and prompts are in [assets/knight-gait-v2.md](assets/knight-gait-v2.md); diagonal assets and prompts are in [assets/knight-diagonals-v3.md](assets/knight-diagonals-v3.md). `assets/knight-art.json` defines the sheet grid and idle mapping for both build and preview. `prepare-knight-gait.py` derives frame bounds, helmet registration and ground anchors without modifying source PNGs. Run it after changing the Knight source art, then `node integrate.cjs` to rebuild the offline game. The rejected halfway sheets remain as source references but are no longer embedded or decoded by the game.

Mage/Rogue retain coherent eight-pose walk cycles and eight-step action timelines. Hero world sprites/shadows are 15% smaller; portrait sizes and gameplay collision remain unchanged. `prepare-hero-frames.py` maintains the earlier sheet metadata. `test-hero-animation.cjs` covers frame bounds, rendering, world scale, essential animation under reduced motion, non-mirroring and planted Knight idle. `test-knight-gait.cjs` covers four directions, actual movement speed, distance cadence, stopping, direction stability, source bounds, ground anchors and preview controls. `test-knight-diagonals.cjs` checks all four diagonal key combinations, normalized speed, phase continuity, view retention, planted idles, frame bounds and angular overlap on desktop/mobile layouts. Tests exercise desktop Chromium and mobile viewports; physical iPhone Safari validation remains a device check.

### Combat and sprite playback refinement

`combat.js` owns distance-based animation clocks. Rendering does not advance them. Slowing physical movement slows cadence; blocked movement freezes gait and heroes preserve their phase between stops. Walk visuals take priority over basic attacks while moving. Attacks and skills use local action timers and clamp at the final frame. Reduced motion keeps essential walk/action poses active while suppressing cosmetic impacts/bobbing.

Projectiles sample traveled segments in 4px increments and resolve the first cover/character hit in travel order. Simulation-timed impact sparks respect reduced motion and clear on restart. Damage, cooldowns, class speeds, rewards and rival tuning are unchanged. `test-combat.cjs` checks gait, blocking, timestep independence, stop/restart, action frames, swept hits, cover order, impacts and restart across all three classes.
### Camp companions and stable wall textures

The other two classes now defend camp against ordinary mobs, pursuing nearby targets and returning to their fireside positions afterward. Knight uses melee; Mage/Rogue fire real projectiles. Helpers use 75% of normal basic attack damage and a slightly slower attack interval, do not take damage, and remain in camp. Their kills use normal minion/reinforcement bookkeeping. Companion state resets with matches and clears upon dungeon simulation; boss selection already clears projectiles. Pausing stops all companion actions. `test-camp-allies.cjs` verifies independent kills by all three companion classes, kill accounting, pausing, dungeon exclusion and reset.

Warlord masonry now uses a cached, world-anchored material pattern rather than restarting the texture at the visible camera edge. `test-walls.cjs` compares identical world-space wall pixels before/after scrolling for every theme on desktop/mobile, in addition to collision and reachability checks.

### Raised wall perspective

`walls.js` gives solid masonry and short wall blocks a raised, offset top, darker side/front faces, highlighted coping stones and cast/contact shadows. Necromancer uses pale funerary-stone caps against dark jade faces; Pyromancer uses warm copper/basalt caps against charcoal faces. Dungeon perimeter trim receives the same treatment. Existing materials are reused, with no new image downloads. Projection is cosmetic: movement, navigation, projectiles and gates retain their original footprint masks. `test-walls.cjs` captures desktop/mobile views and verifies unchanged masks, objective reachability and solid movement blocking for all three environments.

### Campsite floor and buff artwork

Heroes' Camp now uses detailed grass, packed earth, rustic cobblestone and forest-litter materials from `assets/camp-materials-v1.png`. The ground is composed once into a cached camp canvas. Buffs use higher-detail sword/shield/crystal/hourglass sprites in 80px UI canvases and on the reward shrine. Active and spent shrine artwork replaces the plain rectangular altar. The atlas is embedded for offline play; exact benefits, costs and durations remain unchanged and visible. `assets/camp-buffs-v1.md` records the generation and transparency-cleanup prompts. `test-camp-buffs.cjs` checks all four distinct icons, high-density canvases, unchanged config/masks, exact reward copy and touch/mouse claiming.

### Narrative cues, entrances and heroes' camp

`journey.js` replaces painted `BOSS` and `GUARDED` floor text with a wounded scout giving a themed plea and directions, worn tracks along the main route, and a supply-cache cue on the eastern detour. Reward previews still show exact benefits, drawbacks and durations before commitment. Dialogue and collection never pause the race.

The north gate is now an open royal archway for Warlord, a crypt doorway for Necromancer, and carved volcanic pillars for Pyromancer. Two explicit side-post masks block the architectural supports while the central opening retains the existing immediate boss transition. Sprite opacity is never a collision source.

The selection/waiting room is now Heroes' Camp, with seeded earth/grass, tents, campfire/cooking pot, bedrolls, supply table and the other two playable classes resting nearby. Camp props are cosmetic; companion heroes now assist against ordinary camp waves. Existing race, wave, health and boss-order mechanics remain intact. `assets/journey-v1.md` records the prompt and integration details. `test-journey.cjs` checks camp labeling and all three entrance transitions/geometry on desktop and mobile, with generated camp and entrance screenshots.

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

Solid cover blocks projectiles and targeting, including Shadowstep through a wall. Enemies use cached grid paths and optional guards remain in their wing when the player takes the direct route. The Knight can break nearby wooden cover with the manual Attack button.

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

The automated suite includes over 10,600 checks across 27 suites, including 512 authored mob poses, eight-direction movement, standing, attacks, ground anchors, animation clocks and compact runtime atlases. Tests include 36 actual route traversals (three classes × three bosses × both routes × desktop/mobile), 20 generation seeds per boss per primary viewport, visible pre-commitment reward values, unchanged claim options, touch claiming/declining, ongoing timers, all buff effects/lifecycles, healing caps, resets, collisions, hazards, inheritance, full rival progression, telemetry and sample thresholds. Extra viewport checks cover 320×568 portrait and 844×390 landscape, visible ability buttons and touch movement with letterboxing. Preview PNGs and raw `test-results.json` are generated locally and ignored by Git.

Chromium tests and visual checks are complete. Physical iPhone Safari testing, human class win-rate testing, and statistically meaningful reward-payoff testing have not been performed. See `BALANCE.md` before treating provisional values as final balance.

GitHub repository: https://github.com/jagnew1187/mirrored-dungeon. The project tracks the main branch.

### Movement stability build
Walking now uses the original eight coherent poses per direction. Halfway sheets are retained as source material but disabled in playback because their silhouettes differ. Grounded contact poses replace casting poses during idle. Hero gait phase survives stops, with a 100ms pose hold before idle. Movement speed, combat timing, collision and the requested slower gait rate are unchanged.

### Boss movement build
Warlord, Pyromancer and Necromancer use eight authored directions, eight walk poses per direction and separate grounded standing poses. Actual travel drives their gait; attacks, skills, speed, damage and inheritance retain existing behavior. Only the selected boss's movement textures preload during its gauntlet, then cache at 2× body resolution. Open `boss-walk-review.html` to compare views and poses. Rebuild metadata with `python prepare-boss-gaits.py`, run `node integrate.cjs`, and regenerate the review with `node make-boss-preview.cjs`. Asset prompts and limitations are documented in `assets/boss-gaits-v2.md`.

### Boss skill artwork
Boss skills now have nine-pose axe-slam, fire-cast and summoning sequences matching the new movement sprites. The existing 0.78 second action clock drives playback, with the casting side held through the animation. Ability triggers, projectiles, telegraphs, damage, cooldowns and inheritance stay unchanged. Rebuild with `python prepare-boss-skills.py`, `node integrate.cjs` and `node make-boss-skill-preview.cjs`. Open `boss-skill-review.html` to inspect poses. `test-boss-skills.cjs` checks skill artwork, original ability behavior, direction, pause and mobile layouts.

### Mob animation artwork
Cultists, skeleton soldiers, acolytes and crystal hounds share new eight-direction movement and attacks across themed dungeons, waves, summons and camp. Each authored view has eight walk poses, a planted standing pose and seven attack poses. Actual travel drives walking; stopping retains phase and direction. An attack holds its target direction and takes visual priority over walking for the existing 0.45 second action window. Existing contact damage, AI, cooldowns, collision, wave logic and companion combat stay unchanged. Textures load on first use per mob design and cache at twice displayed body resolution. Rebuild metadata with `python prepare-mob-animation.py`, compile compact atlases with `node compile-mob-atlases.cjs`, build with `node integrate.cjs`, and generate `mob-animation-review.html` with `node make-mob-preview.cjs`. `test-mob-animation.cjs` verifies AI pursuit, pose selection, grounded feet, attacks, pause, resets and desktop/mobile rendering. Asset prompts are in `assets/mob-animation-v1.md`.



Hold **Shift** to stand still. While held, left-click or hold left mouse to attack
toward the cursor, including empty ground (Mage and Rogue projectiles; Knight
directional swings). Release the mouse to stop free fire; release Shift to move
again. Existing click-to-move/enemy selection and touch controls still apply.
