# Pass 02 delivery — gameplay rebuilt, art acceptance incomplete

The existing Godot project now has a substantially different playable foundation, verified with actual input-driven engine sequences and rendered evidence. **This pass does not satisfy the complete requested definition of done.** Dedicated trees/vegetation and civilian architectural artwork are still missing. The remaining flat tree silhouettes and repetitive textured building studies are visibly below the requested standard; they are not final artwork. No claim of enjoyable combat or complete visual polish is based on automated checks.

## Actual changes and bugs fixed

1. Hero movement now uses CharacterBody2D and matched StaticBody2D footprints; AnimatedSprite2D owns eight-direction walking, proper Knight idle poses and timed source attack sequences. Changing state does not restart an unchanged animation. Collider-blocked movement returns to idle rather than appearing to slide.
2. The old all-class instantaneous circular attack was replaced. Knight hits a directional 85px sector at the strike frame; Mage and Rogue release ranged projectiles at their animation release frame. Class stats follow the JavaScript CLASSES table. Projectiles stop at solid cover.
3. Commands can be held or buffered for one next attack. The former short buffer could expire before cooldown, dropping input; it now lasts through the current cooldown. Clicked enemies are approached into range and targeted. Movement cancels the approach.
4. Added visible anticipation/recovery, projectile travel, target marker, damage numbers and hit tint/stagger. Enemies have explicit idle/wander/pursuit/windup/return states, collision-aware routes, bounded roaming and independent quest ownership. Dead enemies are removed before subsequent AI updates.
5. NPC approach used a ring and stop tolerance that could terminate just outside dialogue range. Candidates now lie on a 38px ring inside a 72px interaction range. Closest-hit selection avoids picking the first overlapping NPC. Mara/Bram/Finn retain correct distinct dialogue and portraits.
6. Main menu, character selection, settings, pause, quit confirmation, protected stash and NPC dialogue are separate screens. HUD and attack controls hide behind critical modals. Gameplay button focus no longer consumes movement/attack keys. Held action input is disarmed across transitions until released.
7. Vigil now uses the supplied pavilion, actual chest, supplies, table, tents and campfire around a blended worn clearing. The curved approach follows the source layout intent; there is visible ember/glow feedback. Ground transitions use original material textures, not flat polygons.
8. Runtime inspection caught pale blank doors: textures created only inside `_draw()` were released before rendering. They now have retained references. Wall texture sampling uses the flat front region rather than repeatedly tiling the whole freestanding wall prop. Tall foreground fade covers tree canopies as well as trunks.

## Evidence, not just resource tests

- **52 playthrough assertions passed** both headless and in the actual graphical Compatibility renderer. The sequence clicks the menu, visits all three camp NPCs, restocks the stash, moves/attacks with each class, walks the road branch, approaches and fights both quest guards, recovers flour, walks into Bannerfall, talks to Anja, checks camera boundaries, recovers from death and opens Settings.
- **18 contract assertions passed** for native collision, cancellation, missing-enemy protection, strike timing/direction, queued attacks, pause, UI layering, leash/cooldown separation, touch coordinates/joystick and projectile cover collision.
- **55 actual runtime screenshots**, six eight-frame GIFs and a labeled contact sheet were captured. Main menu, hero selection, camp, walking, attacking, Mara portrait, road, Bannerfall and Settings were visually inspected. Later visual inspection caught and corrected an attack carried across a test class change. Re-rendered sequences show distinct walking and attacking poses rather than a static sliding sprite.
- See TEST_REPORT.md for commands, logs and archive verification. Tests are reproducible; their fixture details and limitations are documented.

## Exact art blocker and remaining problems

The imagegen skill's built-in tool returned **HTTP 403 `invalid_workspace_selected`**. The user authorized CLI fallback if configured; **OPENAI_API_KEY was absent**. Public-source web lookup returned the same workspace failure, and a public GitHub lookup failed DNS resolution. No new artwork was generated or downloaded. Source art was reused wherever available. ART_BLOCKER.md records the attempted prompt and unblock options.

Consequently, woodland perimeter vegetation, proper trees/rocks and cohesive civilian house/roof sprites remain unfinished. Camp is more coherent but is not the fully wooded refuge requested. Town doors and stone textures prove scale/collision, but their reuse of fortress motifs is not a finished bakery/smithy visual identity. The source character action art also has only left/right views, while walking has eight directions. A human still needs to judge animation transitions, attack feel and visual coherence in normal-speed play.

No physical Windows mouse/keyboard playthrough by a human, iPhone/Safari run, successful Web export, portrait-touch layout certification, long-session performance test, or listening/audio-quality test was performed. Engine-injected input is not physical device testing. Audio cues are reused and connected, but accelerated tests mute the mixer. Early accelerated audio tests emitted WAV playback cleanup warnings; real-time audio behavior remains a manual verification item.

The slice still has session-only progress, no full stash inventory/talents, no advanced skill migration, no full story, Arena, Endless Descent, companions or co-op. Health restores on travel/class change as in the POC. No full migration is claimed.

## Preservation and next milestone

`../checkpoints/Godot_before_pass02.zip` preserves the original project before this pass. `javascript_before_pass02.json` records preservation hashes. The existing branch was not switched, no commit/reset was made, and the JavaScript source/assets/build/deployment were not edited. The updated project and verified ZIP are separate from that live build.

Next milestone: **finish and approve Vigil's art and normal-speed feel before adding areas.** Restore an art-production path or supply a small licensed set of trees, foliage, rocks, civilian walls/roofs and doors; replace the explicit studies, then have the user play all three classes at normal speed and tune from that feedback. Keep JavaScript authoritative. This pass demonstrates a stronger engine implementation, not readiness to replace the game.
