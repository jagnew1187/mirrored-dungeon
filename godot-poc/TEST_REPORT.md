# Current verification — Pass 07, 1 November 2026

184 distinct checks pass: Pass05 66, contracts 18, Pass06 combat 52, Pass06 campaign 30, Pass07 visual contracts 18. Graphical visual rerun and two duplicate Knight campaign-capture assertions also pass. Full all-class engine routes retain ordinary combat, flour, Anja, Vigil and Continue. Native desktop acceptance is incomplete; no further Computer Use was performed after the user's request to omit it.

Final logs: tests/pass07-final-*.txt, tests/pass07-render-final*.txt, tests/pass07_campaign_capture-render-final*.txt. Evidence: 55 real Godot viewport images in tests/pass07-captures. Resource samples: tests/pass07_performance-render-final.txt. Scope, startup certificate warning and intentional blocked-save fixture are explained in PASS07_REPORT.md. Physical mobile/low-end hardware is untested.

Earlier reports below are historical.

---
CURRENT BUILD: Pass 06. See PASS06_REPORT.md and tests/pass06-final-*.txt. Final: 166 distinct automated checks, 52 graphical rerun checks, zero failures. Native desktop acceptance remains partial.

CURRENT BUILD: See PASS05_REPORT.md and tests/pass05-results.txt / pass05-contracts-results.txt. The report below describes historical Pass 02 only.

# Pass 02 test report

Engine: Godot 4.7.2.stable.official.ed1daf0bf Standard, Windows, Compatibility renderer. Graphical runs reported OpenGL 3.3 / NVIDIA GeForce RTX 3080. Final result: **52 scripted playthrough checks + 18 contract checks passed**. This does not establish subjective polish or satisfy the blocked finished-art requirements. See PASS02_REPORT.md.

## Exact commands

Run from the repository root. The downloaded engine was extracted into `.godot-validation`; that tooling folder is excluded from the project archive. `_sc_` enabled self-contained editor configuration. APPDATA was redirected only in the child command environment to avoid sandbox writes to the user's installed Godot profile.

```powershell
$env:APPDATA = Join-Path (Resolve-Path '.godot-validation').Path 'userdata'
$engine = '.\.godot-validation\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path godot-poc --editor --import --quit --log-file tests/pass02-import-engine.log
& $engine --headless --path godot-poc --quit-after 180 --log-file tests/pass02-runtime-engine.log
& $engine --headless --fixed-fps 60 --path godot-poc --script res://tests/pass02_playthrough.gd --quit-after 18000 --log-file tests/pass02-play-engine.log
& $engine --headless --fixed-fps 60 --path godot-poc --script res://tests/pass02_contracts.gd --quit-after 3000 --log-file tests/pass02-contract-engine.log
& $engine --fixed-fps 60 --path godot-poc --script res://tests/pass02_playthrough.gd --quit-after 18000 --log-file tests/pass02-render-engine.log
```

The graphical command was launched with `Start-Process -WindowStyle Hidden` and awaited to completion. The capture script disables vsync for accelerated testing, injects keyboard and viewport mouse input, waits real physics frames, and captures the viewport only after `RenderingServer.frame_post_draw`. `tools/build_evidence.py` assembles original screenshots into labeled crops/GIFs; it does not redraw gameplay. Source screenshots remain intact in `tests/pass02`.

## Results and what they establish

| Test | Result / evidence |
|---|---|
| Editor import | Completed without script/resource errors; original and fresh archive extraction |
| Main scene | Runtime smoke completed |
| Headless full sequence | 52 checks, zero failures; tests/pass02-playthrough.log |
| Graphical full sequence | 52 checks, zero failures; tests/pass02-render.log, empty render-errors log |
| Contracts | 18 checks, zero failures; tests/pass02-contracts.log |
| Walk playback | At least five distinct live AnimatedSprite2D frames observed per class under held movement; eight captures per class inspected |
| Attack playback | At least five distinct frames per class, delayed impact, real damage and repeated-input defeat; eight captures per class inspected |
| GUI | Viewport mouse events navigate title/selection/settings and dialogue; screenshots reviewed |
| Preservation | SHA-256 comparison against 567 pre-pass existing files; no changed or missing files |
| Packaging | ZIP CRC and byte-for-byte contents verified; fresh extracted project imported and playthrough rerun |

Tests deliberately place each class against a target on a clear existing road segment when checking attack timing and isolate actors for directional assertions. The main traversal/combat sequence uses real navigation, target approach, cooldowns and damage rather than injecting kills. The initial ranged fixture had put a target behind a tree; cover correctly blocked shots, so the fixture was moved to clear terrain. The long traversal runs with ordinary health; no invulnerability or boosted health is left in the screenshots.

The first NPC arrival test exposed an actual grid/tolerance bug and was fixed in implementation. Viewport-local mouse injection corrected the test driver. Inspection exposed a transient-texture rendering bug and carried input during a class switch; both were fixed and captures rerun. Final fixed-step tests mute audio because accelerated engine time does not represent the audio mixer. Earlier rapid audio teardown produced WAV resource cleanup warnings; no listening or audio-quality pass is claimed.

## Limitations and acceptance

- **Visual acceptance remains incomplete:** procedural trees and repetitive architectural material studies are provisional. Dedicated artwork was blocked by unavailable image generation/API configuration/network access.
- No human-operated full playthrough, physical touchscreen, iPhone Safari, portrait usability certification or long-duration profiling.
- No successful Web export: matching export templates are unavailable, as recorded in the prior report. Preset retained; no deployment performed.
- Screenshots and animation sequences demonstrate rendering/playback, not that every direction/action transition is polished. Attack source art has only left/right views.
- No disk saves or campaign migration. No JavaScript regression run; instead, all pre-pass existing files were hash-checked for preservation.
- Prior Pass 01 tests/evidence are archived under tests/history-pass01 and are superseded, not counted again.

The test evidence supports continuing this vertical slice. It does not declare the complete Pass 02 definition of done or Godot replacement readiness.

