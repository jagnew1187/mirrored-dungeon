# Pass 07 status — current

The official imagegen check succeeded in Pass 07. New art is integrated under assets/pass07, with originals and prompts under art-source. ART_PRODUCTION_GUIDE.md and PASS07_REPORT.md are the current authority. The older status below is preserved as historical evidence; its generation-blocked and geometric-tree descriptions no longer describe the current build.

---

# Visual standard and scale — Pass 02

Status: character/prop import, ground blending and interface standard implemented; bespoke trees, vegetation and civilian building art remain **not accepted as finished**. See PASS02_REPORT.md for the blocked generation/download paths. Do not expand the maps using the retained tree/house studies as final art.

## Style target

Detailed 16-bit-inspired dark fantasy; muted sage, warm earth and weathered stone, cream canvas, burgundy/antique-gold accents. High-contrast character silhouettes and readable weapons. Existing supplied character artwork is authoritative. Use an elevated three-quarter camera, feet on a flat 2D ground plane, consistent top/left lighting and tall visual layers above smaller ground footprints. Preserve source alpha and use nearest-neighbor sampling. UI colors: deep green-black `#132320`, parchment `#e5d8bc`, subdued gold `#8d7348`, health red `#9d423f`.

The terrain shader mixes the supplied grass/leaf litter, dirt and cobble textures using continuous path distances and small pixel-scale edge breakup. Vigil has an elliptical worn clearing and curved approach. This is textured layout generation, not an invented replacement raster tileset. The base materials are 64×64 PNGs sampled over 128 world pixels. Do not confuse those material repeats with navigation cells.

## Measurements

| Element | World pixels | Rationale |
|---|---:|---|
| Adult hero nominal body | 72 high | Derived from each source's bodyHeight metadata, independent of weapon extent |
| Hero frame canvas / foot root | 160×128 / (80,112) | Transparent margins permit sword, staff, cape and attack poses without changing the root |
| Mara / other adults / twins | 64 / 64 / 43 high | Seven-year-old twins share body art; distinct stable IDs |
| Hero/enemy physical collider | radius 12 | Feet-plane collision, not full portrait rectangle |
| Navigation cell / clearance | 24 / radius 13 | Slightly conservative against static rectangular footprints; no diagonal corner cuts |
| Interaction distance / candidate ring | 72 / 38 | Allows grid-center rounding and movement stopping tolerance without stranding NPC approach |
| Camp tent / pavilion footprint | 210×100 / 230×100 | Visual art extends above footprints; not miniature roofs |
| House footprint | 230–350 wide × 100–200 deep | Source-textured structural study only |
| Door visual framing | 76×94 | Arch is taller than 72px hero; detailed civilian doors still required |
| Main road | roughly 86px cobble core, 210px worn edge | Allows multiple people; town crossing has broader visible junction |
| Gate visual | 160×240 | Retained detailed source arch; collision pillars are separate structures |
| Camp / wilderness / town | 1152×720 / 3072×2112 / 2112×1536 | Preserve small camp and scrolling district boundaries |

Movement derives from JavaScript CLASSES: Knight 204px/s, Mage 225px/s, Rogue 280px/s. Walk playback is 12 frames/sec, eight frames and eight directions; body-root alignment is shared. Knight has separately authored left/right attacks, not a mirrored shield. Mage/Rogue action art mirrors horizontally for left-facing casts/throws, matching the source implementation. Attack duration is .32 seconds; release is .16 seconds for Knight/Mage and .12 seconds for Rogue. Up/down attacks use the source's available left/right action views; full eight-direction attack art is not claimed.

## Depth and architecture

CharacterBody2D provides foot collision; AnimatedSprite2D provides playback. StaticBody2D rectangles use the same footprints as AStarGrid2D. Y sorting is based on ground positions, not image centers. Foreground trees/structures fade to .42 alpha while covering the hero; tree fade bounds cover the canopy rather than only the trunk. One area is instantiated at a time. Future town expansion should create connected district scenes; this pass adds no city streaming system.

## Asset inventory / provenance

- `assets/source-inventory.json`: 111 original source PNG filenames, dimensions and formats.
- `assets/manifest.json`: 244 isolated gait, NPC, material and camp outputs with source rectangles/anchors. Includes all eight hero directions.
- `assets/pass02-manifest.json`: 63 additional attack/idle/prop outputs with source metadata. 48 action frames, four Knight idle poses and eleven environmental props.
- `tools/extract_assets.py` and `tools/pass02_assets.py`: reproducible conversion from the unchanged parent repository. Not required to play the distributed project.
- `assets/AUDIO_CREDITS.md`: source combat bank provenance. Six cues reused: sword swing, dagger throw, arcane cast, metal/flesh/arcane hit. Physical samples originate from Kenney CC0 packs; original spell cue synthesis is documented in the repository.
- Supplied sprites/materials/props were generated for the original project, as recorded in its art notes. No new ownership/license claim is made and no external art was downloaded.
- `arch.png`, `pavilion.png`, `chest.png`, `masonry.png`, barrels/crates/banner all come from inspected existing atlases. House facades use a cropped front-face region of the masonry texture; roofs use a source ground texture as a **temporary material study**, not final roof art.

Imagegen skill was applied. Built-in generation failed with HTTP 403 `invalid_workspace_selected`; user-authorized CLI fallback could not run because OPENAI_API_KEY was not configured. No replacement image was produced. Web lookup failed with the same workspace error; public asset download also failed DNS resolution. The attempted generation prompt is saved in ART_BLOCKER.md. Existing tree geometry is explicitly retained as provisional and fails the finished-art requirement.

