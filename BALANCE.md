# Strategic gauntlet balance notes

## Measured route timing

The browser pilot walks the actual generated room, uses normal movement and available class skills, fights optional guards, claims a reward, returns along the side passage and enters the existing boss encounter. These are scripted traversal measurements, not human completion times or boss win-rate measurements. Seed: 42017; default difficulty; 840×620 desktop arena and 560×680 portrait mobile arena.

| Class | Direct route, all bosses | Reward route, all bosses | Additional detour time |
| --- | --- | --- | --- |
| Mage | 14.16–14.64s | 24.48–27.08s | 10.32–12.44s |
| Knight | 15.60s | 25.32–30.24s | 9.72–14.64s |
| Rogue | 10.16–10.56s | 20.52–22.32s | 10.36–11.76s |

All tested direct routes are within the initial 10–25 second target, and every measured reward detour adds 8–15 seconds. These times arise from room dimensions, movement, abilities and combat. There is no gate countdown or reward unlock timer. The Rogue's Shadowstep shortens traversals; the Knight's extra health and close-range damage remain distinct advantages.

## Recommended next balancing pass

1. Compare total gauntlet plus boss times for direct versus each reward, grouped by class, boss and empowerment. A useful boss damage buff may still cost more time than it saves; that is an intended strategic outcome. Check survival and health alongside clear times before weakening recovery or defensive rewards.
2. Watch Rogue Shadowstep and route skip opportunities across more seeds. The pilot's direct runs are about four to five seconds faster than the Mage's. Validate competitive match outcomes before reducing mobility or changing class statistics.
3. Watch Knight/Necromancer detours. The desktop pilot's additional 14.64 seconds is near the upper target. If human tests regularly exceed 15 seconds, reduce summoner guard health or detour depth before weakening the Knight's core abilities.
4. Evaluate Edge (+25% damage / +20% damage taken for 15s), Ward (70% mitigation / −12% movement for 10s), Surge (25% shorter cooldowns / −15% basic attack speed for 15s), and 30% Restoration against empowered bosses and low-health entries. Do not assume more power must always repay the detour. Use the local telemetry sample threshold before flagging selection patterns.
5. Calibrate rival attack uptime and dodge settings against human clear times. Its same-seed strategy simulation is not a physical replay, so route and combat estimates need real playtesting.

## Limits of current validation

920 counted automated checks passed across desktop, 390×844 mobile, 320×568 compact portrait and 844×390 landscape. Source and generated HTML are synchronized. Mobile screenshots were visually inspected; fixed landscape ability controls and coordinate mapping for letterboxed canvases were verified.

Physical iPhone Safari performance, touch comfort on a device, long-session frame pacing and human win-rate/reward-payoff studies remain untested. There is no multiplayer networking. Rival movement and hazard exposure are estimated by its strategy/combat model, whereas player route tests use the actual collision and movement systems. The sample-gated report does not infer causal balance from a few scripted runs and never changes statistics based on race position.

## Risk/reward telemetry

The balance report now separates detour cost from boss time saved and reports the resulting net seconds and percent. Negative net seconds means taking the reward was faster; positive means slower. Successful-clear comparisons are grouped by class, boss, empowerment, seed and tuning. Completion rates accompany them so recovery and defense are not assessed by speed alone. Synthetic regression tests verify both a buff that speeds up the boss but loses time overall and one that recovers its detour cost. Those fixtures are tests, not evidence of live balance.

All penalties and their durations are configurable in each reward's drawback object. Ward's movement penalty survives shield consumption until its ten seconds finish, and every combat effect is cleared on boss completion or restart. The rival uses the same modifier calculation; its analytic model represents movement penalties through reduced dodge effectiveness. Physical Safari and human reward-payoff studies remain outstanding.
