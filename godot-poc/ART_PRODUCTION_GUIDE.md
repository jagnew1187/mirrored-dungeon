# Mirrored Dungeon art production guide — Pass 07

Updated 1 November 2026. This supersedes the Pass 02 visual-status notes. The playable project is `godot-poc/project.godot`, Godot 4.7.2 Standard, Compatibility renderer. The parent JavaScript assets remain unchanged.

## Style and scale

Detailed dark-fantasy pixel art, elevated three-quarter perspective, top-left light. Use irregular organic foliage clusters, weathered timber, warm plaster, restrained iron and cloth accents. Keep character silhouettes brighter than ground detail. Do not use castle walls as civilian facades. The new generated environment is a substantial visual improvement, but its texture density still differs slightly from the supplied character art; future production cleanup should harmonize both.

| Element | Contract |
|---|---|
| World/display | One texture pixel per world pixel for new props; nearest filtering, no mipmaps or fractional prop scaling |
| Terrain | Existing 64 × 64 source materials repeat over 128 world pixels; 24px navigation cells are separate from art tiles |
| Heroes | Nominal body height 72px; 160 × 128 RGBA cell; foot origin (80,112); 8 frames per attack direction |
| Adult NPCs / twins | Existing 64px / 43px height; unchanged roots |
| Enemies | 66px body, officer 76px; 128 × 128 cell, foot origin (64,116); all retain radius-12 colliders |
| Trees | Oak 256px, pine 288px, birch 270px visual height; 24 × 22 trunk collision; canopy is not solid |
| Understory | Shrub 88px, rock cluster 72px, fallen log 68px high; non-solid edge dressing, kept outside road buffers |
| Buildings | New sprites 230–330px high; existing ground footprints 230–350px wide and 100–200px deep remain authoritative |
| Doors | Approximately 54 × 80px door component, suitable for a 72px hero; no interiors in this slice |
| Roads | Existing approximately 86px cobble core and 210px worn margins; geometry and camera limits unchanged |

Palette families: deep foliage `#19392f`, moss/olive highlights, bark umber, plaster ochre, desaturated slate, russet shingles, burgundy cloth. UI retains green-black `#132320`, parchment `#e5d8bc`, gold `#8d7348` and health red `#9d423f`. Effects use pale cyan, muted gold and brief amber impact sparks, with little filled area.

## Import, atlas and origin rules

`tools/pass07_art.py` reproduces project-local assets from `art-source/` and unchanged original hero frames. Pillow is needed only to rebuild artwork, not to play. Original generated RGBA sheets are preserved. Runtime crops use nearest resizing and a 120/255 alpha threshold; this removes soft halos at native game scale. Source alpha is retained in the original sheets.

Hero atlases are 1280 × 1024: eight columns, eight direction rows in right, southeast, down, southwest, left, northwest, up, northeast order. `AtlasTexture.filter_clip` is enabled. All frames have at least a two-pixel transparent outer gutter; the visual suite checks actual used rectangles as well as atlas regions. Body/face sprites are never rotated. Only an isolated weapon-arm layer is rotated around its shoulder in the interim directional rig. The upward Knight sword is shortened locally to stay inside the canvas.

Enemy atlases are 512 × 512. Companion JSON maps each eight-frame state sequence onto deduplicated 128px cells. Do not assume one state per atlas row. Shared `SpriteFrames` are cached by class or enemy role. Enemy death visuals stop colliding and targeting immediately, then disappear within .8 seconds; they do not remain as accumulating corpses.

Normal attack duration remains .32s, impact .16s Knight/Mage and .12s Rogue. The actor maps animation progress around the actual impact time, including ability windup/recovery. Ability duration is assigned before playback starts. Ranged effects use measured directional visual muzzle offsets blended back to the existing chest-height flight path during the first 70px. Ground trajectories, hit tests, cover, speed, damage and range are unchanged.

## Layers and occlusion

Terrain is behind foot-sorted actors/props. Static colliders and AStar use the same established ground rectangles. Never use an entire roof or canopy rectangle as collision geometry. New camp trees add only their small trunk footprints; road solids, enemy homes and building footprints are preserved.

Foreground trees/buildings fade gradually to .32 when covering the hero or a visible enemy. Tree trunks retain their bottom 38px; building facades retain their bottom 80px. This preserves grounded bases while revealing covered actors. Tent/pavilion art fades as a whole. Prop visibility is culled beyond a conservative camera margin. Static artwork is not redrawn every frame; fading and visible fire are exceptions.

## Reusable environment kit

`assets/pass07/` contains oak, pine, birch, shrub, rock and log sprites, plus bakery, smithy, residence, ration storehouse, mill and checkpoint building sprites. These six complete building assemblies replace the fortress-material studies. They are reusable variants, not a procedural building-construction system.

`civilian_kit.png` / `.json` additionally provide a timber door, shuttered window, roof shingles, timber wall, stone foundation and bakery sign with explicit atlas rectangles. These are material/trim crops for future local composition, **not seamless tiles**. Finished buildings currently use complete sprite assemblies; the trim sheet is not loaded during gameplay. Future houses should follow the same height, perspective and door scale.

Vigil retains its compact practical layout, all three residents, shelter, pavilion, fire, chest, supplies and exit. Woodland edges, roots, rock clusters, fallen timber and shrubs add depth without filling the central interaction space. Old Mill Road reuses the kit with deterministic placement and a 120px road-decoration exclusion buffer; vegetation does not expand the map or change encounter populations.

## Honest animation status and remaining source requirements

The official imagegen availability check succeeded. Three subsequent production requests supplied civilian buildings, enemy poses and hero release poses. Source prompts and provenance are in `art-source/PROMPTS.md`; no external commercial artwork was downloaded.

For each hero, the six formerly missing directions now have one generated release pose, local weapon-arm anticipation/release/recovery, and original idle endpoints, assembled into eight timed frames. Existing left/right attacks remain source-derived. These are usable directional **interim animations**, not 144 independently painted new poses. All 144 full production frames (six directions × eight frames × three heroes) remain an authored-art replacement target. Dedicated Shield Guard, Cleave, Burst, Focused Bolt, dash and twin-release body animations also remain future work.

Enemies now have distinct generated idle and attack silhouettes: kettle-helmet militia, longbow archer, kite-shield soldier, twin-knife raider, and larger poleaxe officer. Idle/walk, windup, recovery, hurt and collapse are limited local adaptations of those two poses. Full leg cycles, dedicated anticipation/hurt/death anatomy and eight-direction enemy poses remain unfinished. Horizontal mirroring swaps asymmetric enemy equipment and is acceptable only as the current provisional treatment.

Before approving replacement art: inspect every direction at 1×, verify feet/weapon roots and transparent gutters, verify impact/release timing, walk behind roofs and trees, run `tests/pass07.gd` and the gameplay suites, then perform human desktop/mobile acceptance when requested. A passing texture test does not establish artistic quality or physical-device performance.
