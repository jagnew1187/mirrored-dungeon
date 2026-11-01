# Pass 07 — visual overhaul and verification

Completed implementation review on 1 November 2026, continuing work begun 26 October. Active project: `godot-poc/project.godot`, Godot 4.7.2 Standard / Compatibility. This pass delivers a substantial visual improvement with explicitly interim character animation. Full desktop acceptance is **not claimed**; the user requested no further Computer Use testing on 1 November to conserve usage time.

## What changed

- Replaced geometric woodland trees with detailed oak, pine and birch art. Added shrubs, mossy rocks, roots and fallen timber around Vigil and Old Mill Road. Camp interactions, compact layout, road geometry, map boundaries and enemy homes remain intact.
- Replaced fortress-textured houses with civilian bakery, smithy, residences, ration storehouse, mill and checkpoint sprites. Added a reusable trim/material atlas. Buildings retain feet-based sorting and their existing ground collision rectangles; roofs and canopies fade for the hero and enemies.
- Added eight-direction attack selection for all heroes, fixed roots and clipped atlas regions. Six directions per class use generated key poses and a local weapon-arm rig; left/right retain existing attacks. Corrected the upward Knight sword clipping and synchronized release frames with gameplay windup.
- Fixed ability animation speed using the previous attack duration: the current duration is now assigned before playback. Added directional guard presentation, cleave anticipation/sweep, burst runes, focused-bolt shape/trail, dash sprite echoes, distinct twin-dagger colors, directional visual emission offsets and impact sparks. Damage, cooldowns, ranges, movement and save mechanics are unchanged.
- Added distinct equipment/body silhouettes for all five enemy roles and state-driven visual playback. Death clears collision/targeting immediately while a short visual collapse finishes. Shared atlases deduplicate repeated frames.
- Improved enemy name backgrounds/HUD avoidance and item-category ground icons. Preserved the existing loot label layout, inventory/comparison/dialogue interfaces and large combat buttons. HUD text refresh is bounded to 20Hz instead of allocating new strings every rendered frame.

The existing terrain shader/material transitions, fire glow/embers, tents, pavilion, furniture and supplied NPC portraits were retained. No city/map expansion, story rewrite, multiplayer or JavaScript changes were made. `campaign.gd` and `items.gd` remain unchanged; save version stays 2.

## Verification

Baseline before implementation: 166 checks across the four existing suites, all passed. Final results:

| Suite | Checks | Failures |
|---|---:|---:|
| `tests/pass05.gd` | 66 | 0 |
| `tests/pass02_contracts.gd` | 18 | 0 |
| `tests/pass06.gd` | 52 | 0 |
| `tests/pass06_campaign.gd` | 30 | 0 |
| `tests/pass07.gd` | 18 | 0 |
| **Distinct assertions** | **184** | **0** |

The visual suite groups related checks: all 24 class/direction combinations, eight-frame region bounds, transparent gutters, roots, release timing, attack-to-idle transitions, six ability facings/durations, NPC/exit reachability in all areas, Y sorting, role atlas/state selection, collision radius and foreground fading. Existing suites cover targeting, cover, loot/equipment/stash, death recovery, quest progression, slot isolation and legacy-save migration.

All three engine-driven campaign loops defeat the ordinary roles, both quest guards and optional Enforcer using real attacks and unchanged health/damage, then recover flour, deliver to Anja, return to Vigil and Continue the saved completed campaign. Combat/travel simulation results remain Knight 27.5s / 224.7 HP, Mage 32.0s / 170 HP, Rogue 28.4s / 135 HP. These are scripted-controller observations, not human difficulty ratings or isolated kill times.

Graphical `pass07.gd` passes the same 18 checks. A separate graphical Knight route passes two duplicate assertions and records actual quest/Continue screenshots; those are not added to the 184 count. Logs are `tests/pass07-final-*.txt`, `pass07-render-final*.txt`, and `pass07_campaign_capture-render-final*.txt`.

The Pass 05 blocked-write ERROR is intentionally induced by its save-failure fixture. This resumed Windows environment also emits `Failed to read the root certificate store` at engine startup. The game uses no network service; suites and rendering finish successfully. No certificate or operating-system security settings were changed.

## Desktop acceptance boundary

Before the user's stop-testing instruction, Computer Use operated a separately launched Windows game at normal speed in an isolated APPDATA profile. Knight: New Campaign, Mara conversation, camp travel, Old Mill Road arrival, approach to the three ordinary roles and Cleaving Strike were observed. The last observed Knight had 133/270 HP while surrounded; no successful group/elite/quest completion was established in that native run. Mage and Rogue did not receive Pass 07 native routes. No new Computer Use calls were made after the user's 1 November instruction.

Therefore native acceptance for all three full routes, all six abilities in sustained combat, inventory/stash, death recovery and restart remains incomplete. The previous operational obstacle was the delay between observations/actions while combat continued. This is recorded, not used to justify changing balance or substituting injected damage. Historical `desktop-pass06` captures are preserved and do not certify this build. Pass 07 native observations are in the conversation; the saved Pass 07 PNG folder is explicitly engine-generated.

## Visual evidence and remaining art

`tests/pass07-captures/` contains 55 real Godot viewport PNGs: menu, three camp heroes, all 24 directional attack views, anticipation/release views of six abilities, three-area arrivals/environment views, five-role roster states including Enforcer, roof occlusion, inventory, flour retrieval, Anja delivery, camp return and Continue. These were driven through engine APIs, not desktop input. `pass07-source-review.png` and `pass07-processed-review.png` are offline art contact sheets, not gameplay captures; the latter is an intermediate pre-cleanup review.

Visual inspection corrected clipped sword artwork, stray neighboring sprite fragments, enemies hidden by foliage, nameplates under the HUD, and ranged emission starting behind the casting pose. The new environment/building art is integrated and visibly improved. Characters still need production animation: 144 independently authored missing-direction hero frames, dedicated ability poses, and full directional enemy walk/windup/recovery/hurt/death sequences. Current rigged key poses and adapted collapses are provisional. See `ART_PRODUCTION_GUIDE.md` for exact contracts and remaining work.

## Performance observations

Compatibility rendering was exercised on an NVIDIA RTX 3080 at 1152 × 720. The final no-screenshot profile warms each area for 1.2 wall-clock seconds and samples for two seconds, after caching all three heroes:

| Area | Maximum sampled draw calls | Reported texture bytes | Nodes | Node growth |
|---|---:|---:|---:|---:|
| Vigil | 89 | 55,543,023 | 116 | 0 |
| Old Mill Road | 112 | 63,325,309 | 407 | 0 |
| Bannerfall | 41 | 66,812,113 | 81 | 0 |

All 21 new runtime PNGs total 25,145,344 uncompressed RGBA bytes; the trim atlas is not loaded by gameplay. Enemy atlases total 5,242,880 bytes instead of 18,350,080 in the first uncompressed frame layout, saving 13,107,200 bytes. Hero atlases are 1280 × 1024; enemy atlases 512 × 512. Sources are retained for rebuilding, not loaded as game textures.

Static prop textures and class/role animation resources are cached. Props cull outside camera margins; fire redraws only nearby; tree/roof fade redraws only while alpha changes. Enemy distance culling and .65s path refresh remain. Dash echoes are short-lived and bounded; death visuals expire. HUD refresh is 20Hz. No scene-node growth occurred during the short profile.

The profiling command uses fixed simulation delta with VSync disabled, so accelerated frame intervals and Godot's periodically updated process monitor are **not normal-speed frame-rate acceptance**. Monitor spikes remain in the raw log; long-session, low-end-PC and physical-iPhone performance are unverified. No mobile performance claim is made.

## Preservation and delivery

Checkpoint `../checkpoints/pre-pass07-20261026-115655/` preserves pre-change scripts, scenes, tests, project configuration, file hashes, Git status and HEAD. The earlier complete Pass 06 ZIP remains unchanged, SHA-256 `3F8F292800084ADEDAFC40457B57EB2AF2CF7E4922D093CA7B78860433CF7A71`. All earlier checkpoints/archives remain.

Final hash audit: all 567 original JavaScript/source files and 317 pre-existing Godot asset/data files match. Tests and native inspection used redirected validation profiles. The eight installed-profile save files could not be rehashed in the final environment because reads returned access denied; they are **unverified, not detected modifications**. Their earlier recovery checkpoint is preserved. No process launched by this pass was directed to that installed save profile.

Branch remains `main`, HEAD `477ae70194e2b5b1cfe7814b2b724c11bd30cfa6`, with the same 28 pre-existing tracked modifications. Godot remains untracked at repository level. No reset, branch switch, commit, push or deployment. Exact status is `PASS07_GIT_STATUS.txt`; preservation details are `tests/pass07-preservation.json`.

Deliverable archive: `../MirroredDungeon_Godot_Pass07_20261101.zip`. Import its `godot-poc/project.godot` in Godot 4.7.2 Standard and press F5. The packaging script creates a new archive and verifies every member against the project bytes. The obsolete extracted POC was not edited.
