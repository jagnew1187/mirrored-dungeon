# Combat sound bank v2

The physical Foley sources are from Kenney's **RPG Audio** and **Impact Sounds**
packs, both published under Creative Commons Zero (CC0). Original pack licenses
are retained in `source/kenney-rpg/License.txt` and
`source/kenney-impact/License.txt`. Selected original Ogg files and their mapping
are retained under `source/` and `sources.json`.

- https://kenney.nl/assets/rpg-audio
- https://kenney.nl/assets/impact-sounds
- https://creativecommons.org/publicdomain/zero/1.0/

The final game bank is `combat-v2.wav`, mono 44.1 kHz / 16-bit PCM for offline
desktop and Safari decoding. `combat-v2.json` records all clip offsets, durations
and peak level. There are 62 variants across 31 combat/footstep cues. Total decoded
duration is about 30 seconds (roughly 5 MiB of float audio at 44.1 kHz).

Physical cues use a clean primary recording of swishes, cloth, metal, glass,
punches, wood or stone. Magic adds a restrained secondary texture. Leading silence is
trimmed, rumble is filtered, levels are matched, and short fades avoid clicks.
Runtime alternates recorded variants at their original pitch without touching game
RNG. Playback uses isolated clip buffers, dry restrained stereo positioning and an
eight-cue overlap cap. Peak level is limited to 0.62 with no aggressive RMS boost.
Existing release/contact timing and volume controls are preserved. The original
synthesized cues remain a fallback during decoding or if the bank cannot decode.

To rebuild from the retained sources:

1. Set `CHROME_PATH` to a Chromium executable and run `node decode-audio-sources.cjs`.
2. Run `build-combat-audio.py` with Python and NumPy.
3. Run `node integrate.cjs` to rebuild `runtime-assets/sound-bank-v2.js`.

`prepare-audio-sources.py` is only needed to re-extract sources from the original
download archives. Archives and intermediate decoded WAV files are local caches
and are ignored by Git. Normal game builds use the committed final PCM bank and
need no network connection or Python runtime.

Mage arcane, frost and healing cues use original smooth tonal envelopes instead of
reversed glass or detuned layers. Fire uses a short low tone with a quiet filtered
air texture. Cast and impact tails are deliberately short to avoid chatter during
repeated attacks. These generated spell cues have no third-party source samples.
