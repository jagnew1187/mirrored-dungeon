# Pass 02 audit — before implementation

The JavaScript game remains authoritative. Read: root design bible, roadmap, Pass 03/04 changelog, hero-animation.js, combat.js, manual controls, camp layout/materials, campaign NPC/world/population code and current Godot scripts/test report.

| System | JavaScript reference | Pass 01 defect / required correction |
|---|---|---|
| Animation | Movement-distance gait clocks, 8 directions, explicit foot anchors, 8 attack frames | Custom draw clock, only 4 directions, no attack state; resource tests could not prove visible playback. Use AnimatedSprite2D and state-owned playback with frame captures. |
| Movement | Knight 204, Mage 225, Rogue 280 world px/s | All classes 210; axis sliding without Godot physics bodies. Use CharacterBody2D, matching class speeds and collider footprints. |
| Combat | Knight 85px / 34 damage / .53s; Mage 315px / 23 / .60s projectile; Rogue 270px / 19 / .37s projectile | Instant 360-degree shared 30-damage radius; cooldown silently drops inputs; no strike/cast animation, projectile or target approach. Add buffered commands, windup/impact/recovery, facing and visible feedback. |
| Vigil | Offset central fire, curved approach, clearing, tent and pavilion, supplies/table | Two same tents, straight tiled road, no perimeter vegetation, static fire, supplies passed off as stash. Restore source layout and real chest art. |
| Menu | Branded modes, character selection, settings, pause | Generic class list conflates launch/pause; missing settings and mode status. Split screens and style consistently. |
| NPCs | Correct portraits, independently identified twins | Art and proximity logic work; preserve while fixing input focus and hover labels. |
| Terrain/town | Textured materials/props, architectural expansion planned | Abrupt 64px tile stairs and flat procedural houses/trees. Blend source materials; replace geometry with textured art where available. |
| Camera/populations | Clamped world camera, independent authored records | Existing Godot approach is suitable; preserve and exercise in full gameplay sequences. Enemy return state repeatedly toggles at home; add explicit states. |
| Evidence | User's manual experience is authoritative | 145 checks mostly resources/logic, no attack animation proof. Replace stale tests with input-driven sequences and consecutive runtime frames. |

Checkpoint: `../checkpoints/Godot_before_pass02.zip` preserves current project; `javascript_before_pass02.json` hashes 567 existing non-Godot files. No branch/reset operation. Missing art generation attempt returned 403 `invalid_workspace_selected`; do not silently claim replacement art was generated. Source atlases contain usable chest, pavilion, props and gate artwork. Dedicated tree/house replacements require available art or restored generation.
