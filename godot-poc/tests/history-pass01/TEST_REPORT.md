# Verification report

Tested on Windows using the user's downloaded **Godot 4.7.2.stable.official.ed1daf0bf** Standard executable. It was extracted to the separate `.godot-validation` tooling directory. No installed editor configuration was changed. The project branch remained `main`; no commit or branch switch was made because the workspace already contained extensive uncommitted JavaScript work.

## Commands and results

Commands ran from the original repository root. `$engine` below refers to `.godot-validation/Godot_v4.7.2-stable_win64_console.exe`.

```powershell
$env:APPDATA = Join-Path (Resolve-Path '.godot-validation').Path 'userdata'
& $engine --headless --path godot-poc --editor --import --quit --log-file tests/import-engine.log
& $engine --headless --path godot-poc --quit-after 120 --log-file tests/runtime-engine.log
& $engine --headless --path godot-poc --log-file tests/engine.log --script res://tests/smoke.gd --quit-after 600
& $engine --headless --path godot-poc --log-file tests/input-engine.log --script res://tests/input_camera.gd --quit-after 600
& $engine --path godot-poc --log-file tests/render-engine.log --script res://tests/capture.gd --quit-after 180
& $engine --headless --path godot-poc --export-release Web exports/web/index.html --log-file tests/web-engine.log
```

The graphical capture process was launched with PowerShell `Start-Process -WindowStyle Hidden` and captured its real viewport after `RenderingServer.frame_post_draw`. Rendering reported **OpenGL 3.3 NVIDIA 610.88 / GeForce RTX 3080 / Compatibility**. Five engine-rendered PNGs were inspected, and layout/foreground visibility improvements were made. These are actual running-engine images, not mockups.

| Validation | Result |
|---|---|
| Editor/import | Completed without script/resource errors after sandbox user-data redirection |
| Main project runtime | 120-frame headless smoke run completed |
| Gameplay suite | **129 checks, 0 failures** |
| Input/camera suite | **16 checks, 0 failures** |
| Graphical rendering | Menu, Vigil, Mara portrait dialogue, road and Bannerfall screenshots captured and inspected |
| Web export | **Failed as expected: matching Web export templates are missing**; no usable Web build produced |
| ZIP | Package tool checks every member byte-for-byte, CRC integrity, project.godot presence and absence of cache/export folders; additionally imported and tested from a fresh extracted copy |

Gameplay tests exercise NPC path completion, separate twin conversations, approach cancellation, collision, all 96 cardinal walk-frame resources, three random/two authored enemies, empty-ledger protection, random kills and cooldown respawn, enemy damage/leash, explicit quest defeats, travel-state retention, flour recovery, town-point reachability and defeat recovery. Input tests inject keyboard and touch events, walk through the camp exit, inspect Camera2D's actual screen center at both map corners, verify independent player movement at a clamp, convert touch through the scrolled camera and exercise joystick press/drag/release. Resource-load checks do not establish the visual quality of every animation frame.

Initial runs exposed sandbox write restrictions for Godot's normal AppData paths. Redirecting APPDATA to a workspace tooling folder and using Godot's self-contained editor marker resolved those environment errors; neither workaround is needed for a normal Windows import. A first leash assertion incorrectly checked an enemy already at home; the corrected test displaces it first. A follow-up test assumed two separate attacks could not kill two nearby guards, and was fixed to allow the implemented area attack. Final results above are from corrected, rerun suites. Logs in `tests/` record the final checks and the failed Web export.

## Completion checklist

- [x] Native project.godot and real main scene.
- [x] Playable camp and automated walk/interaction transition to road.
- [x] Large road, camera follow/clamps and return transitions.
- [x] Traversable Bannerfall sample with scaled structural footprints, gate and NPCs.
- [x] Mara/Bram/Finn interactions and matching portrait dialogue.
- [x] NPC approach and automatic dialogue; combat/menu/manual input cancel pending travel.
- [x] Independent random and authored encounter populations.
- [x] Isolated art frames, Godot imports, animation resources and rendered view checks.
- [x] Windows import/run documentation and self-contained archive.
- [x] Existing JavaScript build preserved: no writes or rebuild commands targeted existing source, assets, index.html or deployment files; pre-existing changes were left alone.

## What was not tested or migrated

No human-operated full playthrough, physical touchscreen, iPhone/Safari, Web runtime, Windows executable export, audio, long-duration profiling, multiplayer or old-version compatibility test was performed. Mouse interaction logic was exercised through the game's world-click handler; a physical mouse-driven Windows playthrough was not performed. Synthetic touch input does not establish real-device usability. The 145 automated checks are mostly functional/resource checks, not 145 independent full playthroughs.

Environment art remains procedural prototype art and the terrain edges are intentionally tile-based. The built-in AStar path uses conservative rectangles rather than polygon navigation; click destinations inside a blocked cell are rejected. Enemies use local pursuit and axis sliding, not full navigation agents. Distant enemies sleep and resume when approached. The comparison has no disk saves, progression, advanced combat, companions, co-op, Arena, Endless Descent or full campaign. No JavaScript regression suite was rerun because that implementation was not edited; its previously existing uncommitted state is not certified by these Godot tests.

Migration judgment: promising for rendering, isolated scenes, camera behavior and local navigation. This evidence supports continuing a comparison, not replacing the browser game or estimating full feature parity.
