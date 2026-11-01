# Pass 07 — 1 November 2026

- Integrated generated woodland, civilian building assemblies/trim kit, distinct occupation soldier silhouettes and directional hero release poses. Original JavaScript and supplied art remain unchanged.
- Added eight-direction attack playback, impact-timed frames, fixed roots, clipped atlas regions, compact role atlases and enemy state visuals. Rigged hero key poses and limited enemy movement/death remain provisional.
- Improved six ability effects, directional ranged emission, hit sparks and dash echoes. Corrected ability playback using the previous duration. Combat values, quest rules and save version 2 are unchanged.
- Added enemy-aware canopy/roof fading, HUD-aware enemy nameplates, category-specific ground loot icons and bounded HUD refresh.
- Passed 184 distinct engine assertions plus graphical reruns and a duplicate Knight quest capture route. Saved 55 real Godot viewport captures. No complete native desktop acceptance is claimed; further Computer Use was omitted at the user's request.
- See PASS07_REPORT.md, ART_PRODUCTION_GUIDE.md and art-source/PROMPTS.md for provenance, verification, resource observations and remaining requirements.
# Pass 06 — 2026-10-26

- Added Shield Guard / Cleaving Strike, Arcane Burst / Focused Bolt, Evasive Step / Twin Daggers with equipment-scaled damage, visible cooldowns, one-command buffering, collision and interruption rules.
- Added militia, archer, shielded soldier and raider behavior; bounded separation, return, sidestep recovery and cover-aware ranged attacks.
- Added optional Mill Enforcer sweep/lunge encounter and once-only 45 XP / 15 coin / padded coat reward. Original two-guard flour requirement remains unchanged.
- Fixed residual chase paths after target death, combat feedback drawing behind actors, disabled-button contrast, enemy name overlap and clustered loot label layout/click targets.
- Added explicit touch combat controls and GUI mouse emulation without duplicate world commands; aligned attack playback with ability durations.
- Kept save version 2, original class stats, progression, equipment and economy. Preserved all 567 original files and existing saves.
- Verified 166 automated checks plus 52 graphical checks. Native inspection is partial: Mage/Rogue full quest acceptance and Knight elite acceptance remain unfinished. See PASS06_REPORT.md and its prioritized continuation.
- No new character/environment art, networking, hosting, deployment or JavaScript modifications.

# Pass 05 — 2026-10-26

- Added stable item catalog, class-aware equipment, central calculated stats, finite backpack and protected stash, stackable healing supplies, persistent ground loot, camp buy/sell confirmations and stale-action guards.
- Added version 2 per-hero campaign records with validated temporary writes, valid-backup recovery and migration of the minimal Pass 04 equipment flags. No browser save migration.
- Integrated XP/levels, once-only combat and quest rewards, recovery, checkpoint travel and live equipment damage.
- Replaced roster behavior with camp supplies; added optional hero names and separate New Campaign/Continue selection.
- Fixed inventory background sizing during page changes, toast/objective overlap, missing visible flour crate, clipped short-footprint labels and current/max HP display.
- Preserved old archives and JavaScript; new archive uses exclusive creation. Historical one-shot scripts/tests retained as text.

# Pass 04 — 2026-10-26

- Added Mara-to-mill-to-Anja quest progression, objective/journal, two-member encounter ledger, explicit flour recovery and once-only bread reward.
- Added basic class growth, equipment hook, Godot-only saves and explicit safe death recovery.
- Tuned enemy windup and solid-cover attack checks; Knight damage uses calculated stats.
- Pass 03 art was not completed; existing provisional trees and civilian building studies remain.

# Godot POC changelog

## 2026-10-25 — Pass 02 gameplay foundation and quality recovery

- Checkpointed Pass 01 and hashed 567 existing non-Godot files before changes. Preserved the existing branch and all JavaScript work.
- Replaced custom-drawn hero playback with CharacterBody2D / AnimatedSprite2D, native static collisions, eight-direction gait, proper Knight idle art, eight-frame attacks and fixed foot anchors.
- Restored source class speeds, health, damage, cooldowns and ranges. Added directional Knight strikes, Mage bolts, Rogue thrown daggers, windup damage, cover collision, hit reactions, damage numbers, buffered/held attacks and target auto-approach.
- Fixed NPC arrival tolerance, closest-NPC hit selection, enemy return/windup state transitions, gameplay-button focus, carried attack input across travel and temporary texture lifetime causing pale doors.
- Split branded title, hero selection, pause, settings, exit confirmation, stash and NPC dialogue. Critical modals hide combat HUD/buttons.
- Restored the camp's curved clearing, pavilion, actual chest and supply/table art. Added source-texture terrain blending, ember/light feedback and source-textured architectural studies. Retained independent authored/random populations and working camera boundaries.
- Extracted 307 isolated PNG assets in total and six existing sound cues. Added source inventory, scale/style guide, actual runtime screenshots and six animation sequences.
- Validation: 52 input-driven playthrough assertions plus 18 contracts; actual graphical capture inspected. Final checks are in TEST_REPORT.md. Accelerated tests mute audio; no human playthrough or device performance claim.
- **Incomplete visual acceptance:** bespoke trees/vegetation and town building art could not be produced or obtained. Built-in generation failed 403; authorized CLI had no API key; asset network access also failed. Retained studies are explicitly provisional. Godot is not declared ready to replace JavaScript.

## 2026-10-25 — standalone comparison

- Added native Godot 4 Standard project with Compatibility renderer, launch menu and three connected area scenes.
- Reused 136 isolated production-art PNGs, with reproducible crop/anchor manifest.
- Added selectable Knight/Mage/Rogue, keyboard and click navigation, screen-to-world touch targeting, virtual joystick, AStar NPC approach, portrait dialogue, stash healing, combat and defeat recovery.
- Added scrolling road, independent bounded random population, stable authored patrol/member records and explicit flour recovery.
- Added representative Bannerfall district, modular terrain, taller buildings, gate/checkpoint, ground-footprint collision, Y sorting and foreground fading.
- Added automated engine tests, rendered screenshots, Web preset, import/export instructions and archive packaging tool.
- Existing JavaScript source, generated index.html, campaign saves, branch and deployment remain outside this POC. No branch switch, commit, save migration or deployment was performed.
- Validation: see TEST_REPORT.md. This is an engine comparison, not production feature parity.

