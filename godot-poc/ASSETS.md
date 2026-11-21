Pass 11 (2026-11-01): six-position party/reserve architecture, individual sheets and equipment, shared inventory, functional talent graphs and derived class evolution. Schema 5 migration; 1,205 automated checks pass. See [Pass 11 report](PASS11_REPORT.md) and [save migration](PASS11_SAVE_MIGRATION.md). Original art is reused unchanged; no companions are automatically recruited.

Pass 10.2 (2026-11-01): ten functional equipment slots, safe schema-4 migration and visible camp recovery. 1,060 automated checks pass. See [Pass 10.2 report](PASS102_REPORT.md) for diagnosis, launch instructions, evidence and limitations. Existing art is unchanged.

# Pass 10.1 asset mapping corrections

All original source/runtime bitmap files are preserved. The boots cell now maps to true footwear metadata. Sandal, ring-gem and token-material labels match their illustrations; Marshal shoulders share the existing actual-pauldron icon, replacing their misleading chest-like image. The compact popup reuses socket art as tiled edge framing. See data/equipment_slot_audit.json and PASS10_1_REPORT.md.

# Current equipment artwork — Pass 10

Original built-in image_gen sources and exact prompts: `art-source/pass10/`. Runtime `assets/pass10/gear-atlas.png` packs 97 individual 64px icons into 640×640; `alcove.png` is a 256×384 illustrated stone display, with `socket.png` and three alpha-cropped hero previews. All game UI uses nearest-filtered art and cached atlas wrappers. `tools/build_pass10_art.py` reproduces packing from checked-in sources with Pillow; no image service is needed to play. Original art/animation files are unchanged. See PASS10_VISUAL_REVIEW.md. Earlier asset notes follow.

# Current interface status — Pass 09

Six original pixel-grid SVG category icons are in assets/pass09. ui_theme.gd and ui_frame.gd provide shared iron/stone/bronze surfaces, rarity/focus states and retained decorative drawing. Existing character/environment art is unchanged. UI text uses linear filtering at fractional scale, while character previews retain nearest filtering. See UI_GUIDE.md and PASS09_REPORT.md. Pass08 animation status and its remaining authored-art requirements below still apply.

---

# Current status — Pass 08

Image generation is available. Distinct combat key poses and drawn fallen bodies are integrated, with sources/prompts in art-source/pass08 and runtime atlases in assets/pass08. The remaining blocker is production animation quality: in-betweens, directional/handedness cleanup and dedicated ability/hurt art. More repeated frames do not resolve it. PASS08_REPORT.md and ART_PRODUCTION_GUIDE.md are current; all material below is historical.

---

# Pass 07 status â€” current

The official imagegen check succeeded in Pass 07. New art is integrated under assets/pass07, with originals and prompts under art-source. ART_PRODUCTION_GUIDE.md and PASS07_REPORT.md are the current authority. The older status below is preserved as historical evidence; its generation-blocked and geometric-tree descriptions no longer describe the current build.

---

# Asset inventory â€” current Pass 02

See **VISUAL_STANDARD.md** for the authoritative current inventory, scale specifications, palette, provenance and unfinished artwork. The earlier 136-asset inventory was superseded by 244 base outputs plus 63 additional idle/action/prop outputs (307 PNG source assets total), with six source audio cues.

- assets/source-inventory.json: 111 original source PNGs with dimensions/formats.
- assets/manifest.json: base source crop/anchor metadata.
- assets/pass02-manifest.json: action/idle/prop metadata.
- assets/AUDIO_CREDITS.md: existing bank provenance and Kenney CC0 source attribution.
- ART_BLOCKER.md: generation failure, fallback configuration limit and attempted prompt.

No new image generation succeeded. Existing art and source metadata were reused. Tree/house studies are explicitly unfinished. Neither metadata nor a loading test is evidence that an animation looks good; inspect the runtime sequences in tests/pass02.

