# SV1 v153 writing and conversion

SV1 1.11.2 saved v153 projects differ structurally from SV2 v196. These are observed fields, not an exhaustive schema for every release.

| Area | SV1 v153 | SV2 v196 contrast |
| --- | --- | --- |
| Note identity | No note `uuid` in inspected saved notes | Note `uuid` present |
| Note mode/cache | `instantMode`, `attributes`, `systemAttributes` | Different pitch and attribute model |
| Retakes | `pitchTakes` and `timbreTakes` | `takes`, including duration retake information |
| Per-phone timing | `attributes.dur` is a relative duration multiplier | `attributes.phonemes[].leftOffset` gives written start offsets |
| Note group | `name`, `uuid`, `parameters`, `vocalModes`, `notes` | Also `pitchControls`, `musicalScale`; parameters include `mouthOpening` |
| Reference identity | No reference `uuid` in inspected v153 references | Reference `uuid` present |
| Mixer | `gainDecibel`, `pan`, `mute`, `solo`, `display` | Additional effect preset/parameter fields |
| File ending | JSON followed by NUL | Inspected files ended after JSON |

The shared reference wiring still applies: `tracks[].groups[].groupID` resolves a `library[].uuid`, and `mainRef.groupID` resolves the track's own group. A library group without references is inactive. A dangling group reference causes a missing-library-group error. The inspected inheriting reference database used `version: "-2"` as the inheritance sentinel.

`dur` is a multiplier, not an absolute number of seconds. Hand-tuned converter constants for consonant lengths do not recover automatic Dreamtonics timings. The inspected SV1 installation did not provide the SV2 project-level duration cache format.

## Converting known phone boundaries to notes

Known SV2 boundaries can be expanded into explicit-phone v153 notes. This requires actual boundary data; absent automatic SV1 timings cannot be reconstructed simply from the serialized `dur` array.

- Preserve the first fragment's syllable lyric and write **`lyrics: " "`** for subsequent explicit-phone fragments. `lyrics: "-"` together with an explicit `phonemes` value produced silence in SV1. Saved SV1 files can also contain an empty string with an explicit phone. This restriction belongs to explicit-phone fragments, not to ordinary `-` continuation lyrics in all contexts.
- Carry language overrides in `attributes.languageOverride` and `phonesetOverride`; the validated generated v153 notes mirrored these into `systemAttributes`. Japanese uses `romaji` as the phoneset.
- If source notes adjoin, the final phone of the earlier note ends at the next note's first-phone start, even when that start is later than the earlier note's nominal end. Taking `min(noteEnd, nextPhoneStart)` introduces a spurious rest in that case. This conversion rule has structural validation; it does not establish complete acoustic equivalence.
- For a template whose notes are already flattened and whose curve coordinates agree, `instantMode: false` with `mainRef.systemPitchDelta` copied to the corresponding group's `parameters.pitchDelta` preserved the template's generated pitch curve. This is not a general mapping of SV2 `pitchControls` to SV1. Account for curve coordinates when changing reference offsets.
- A validated split-note conversion set `dF0Vbr: 0.0` on fragments and `dF0Left`/`dF0Right: 0.0` on syllable-internal edges to suppress per-note vibrato restarts and internal pitch dips. Determine these internal edges across the whole syllable, including continuations spanning several source notes.

Positive durations and nonoverlapping notes establish file geometry, not acoustic equivalence for every fragment size. No universal minimum SV1 phone-note duration has been established here.
