# Pass 04 — campaign foundation

Implemented on the existing Pass 02 project, 26 October 2026. Pass 03 art production was interrupted by inspection requests; its missing woodland/civilian art is not claimed complete.

The three-area loop now has Mara's introduction, a compact objective, optional journal (J), actual two-member patrol gating, explicit flour recovery and Anja's one-time reward. All classes earn combat XP, level with increasing requirements and inspect/equip a modest upgrade (I or camp roster). Enemy windup is 0.38s; strikes respect solid cover and Knight defense. Knight melee now reads calculated attack damage.

New Campaign always creates an additional slot. Continue selects a Godot-only JSON record, with a validated temporary write and a last-valid backup. XP, quest/member ledger, reward claims and equipment persist. Safe arrivals heal and set the recovery checkpoint. Road travel preserves health. Defeat interrupts actions, pauses gameplay and offers recovery or title. No equipment or quest progress is lost. Unfinished enemies reset; completed authored guards remain defeated. No JavaScript storage migration.

Automated validation: pre-change 18 existing contracts passed; post-change all 18 passed. `tests/pass04.gd.txt` (historical source) passed the integrated quest/save/recovery checks for Knight, Mage and Rogue. These tests directly manipulate encounter fixtures and are not normal-speed gameplay acceptance.

Computer Use opened this workspace's project through the Windows Godot project manager and F5. Confirmed new menu, Knight selection, click approach to Mara, dialogue, updated objective, camp departure and scrolling road. Screenshots are in tests/desktop-pass04. Full normal-speed three-class combat/quest/death inspection remains pending; short animation capture is unsupported by the available desktop API. Existing trees and civilian buildings remain provisional, attack artwork remains horizontal only, and no iPhone/performance/audio acceptance is claimed.

Pass 05 followed this checkpoint and replaced the minimal upgrade flag with stable equipment records and expand the stash/economy. The original ZIP remains untouched; checkpoints/Godot_before_pass04_20261026.zip preserves the prior project.

Follow-up: Pass 05 desktop play completed the Knight mill encounter, flour delivery, level-up, equipment, stash and trading loop. See PASS05_REPORT.md for the exact evidence and remaining class coverage.
