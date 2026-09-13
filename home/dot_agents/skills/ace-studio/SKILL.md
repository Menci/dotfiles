---
name: ace-studio
description: Parse, edit, or generate ACE Studio .acep project files directly, including ACEP2 containers, clip coordinates, phoneme data, and parameter curves.
---

# ACE Studio project files

These format details cover inspected ACEP2 projects with content versions 17 and 18. Container version and the decoded project's `version` are separate. Read [container.md](references/container.md) for decoding and serialization limits.

## Coordinates and structure

- Vocal tracks have `type: "sing"`; projects can also contain `audio` and `empty` tracks. Separate singing tracks can carry octave duplicates of the same lyrics, so flattening them together can destroy the intended correspondence during migration.
- Vocal patterns use `timeUnit: "tick"`, with 480 ticks per quarter note. `note.pos` and parameter `offset` belong to the pattern's coordinate system.
- Apply the clip window `[pattern.clipPos, pattern.clipPos + pattern.clipDur)` to local note intervals, then add `pattern.pos`. For example, a local note `[100, 200)` in a clip `[150, 300)` at `pattern.pos = 1000` becomes project `[1150, 1200)`. Do not subtract `clipPos` again. The same clipping and translation apply to curves.
- Inspect `timeUnit` when traversing other pattern types: audio patterns can use seconds. `tempos` contain `position`, `bpm`, and `bend`; the verified timing conversions cover `bend: 0`. Ramp interpolation remains unverified.

## Pronunciation and timing

An inspected vocal note contains `uuid`, `pos`, `dur`, `pitch`, `extraInfo`, `lyric`, `language`, `headConsonants`, `tailConsonants`, `syllable`, and `freezedDefaultSyllable`. `pitch` is a MIDI note number. Preserve per-note `language`: it can differ from the track, including mixed `CHN`, `ENG`, and `JPN` notes within one syllable.

- Effective phones are `(syllable or freezedDefaultSyllable).split()`. A nonempty `syllable` different from `freezedDefaultSyllable` identifies a pronunciation override. It does not establish a timing edit; some notes in other languages have an empty frozen default.
- `headConsonants` and `tailConsonants` contain per-phone durations in **seconds** for these versions. Version 7 is the head-duration conversion boundary; pre-7 head durations use ticks. Leading consonants extend backwards from note onset. For nonempty phone sequences, inspected notes satisfied `len(head) + 1 + len(tail) == len(phones)`: the middle entry is one vowel/final phone, which can itself represent an unsplit Mandarin final such as `ing`.
- The inspected files serialize concrete durations without a separate auto/manual timing flag. Empty head/tail arrays identify absent consonants at those positions. Neither presence nor variation in the values establishes manual editing.
- A continuation note can have `lyric: "-"` and **both syllable fields empty**, with empty consonant arrays. Keep its duration in the preceding syllable's span; an empty phone string does not make it a silent or disposable note.
- A deliberately split syllable can use ordinary notes in several languages. Chinese `i`, JPN `u` ([ɯ]), and ENG `uh ng` can together express a styled [iɯŋ]: ENG `uh` serves as a carrier for `ng`, with its duration taken from the preceding `u` segment. This construction is intentional pronunciation data, not a universal mapping from `ing`. Fragment lyrics alone cannot identify such groups in arbitrary songs.

### Stored tail duration is not an absolute boundary

Extending the next note's leading consonant can move the preceding coda. Consequently, `note_end - sum(tailConsonants)` does **not** reconstruct every effective coda onset. Explicitly split nasal-bearing notes can provide the intended segmentation for a migration, but that does not establish a general renderer formula. Keep stored durations, note segmentation, and effective boundaries distinct; a context-free extraction is not exact rendered phoneme alignment.

## Parameter data

`pattern.parameters` contains segment lists, including `pitchDelta`, `energy`, `gender`, `breathiness`, `tension`, and `real*`/`mamba*` lanes. A `type: "data"` segment has `offset` and `values`, sampled once per tick. A `type: "anchor"` segment stores a **flat** `points` array `[tick, value, tick, value, ...]`; the recovered conversion uses Hermite interpolation. Preserve the representation and unfamiliar lanes when making unrelated edits.

## Skill maintenance

If this skill contains an error, or a task yields worthwhile missing knowledge learned through substantial investigation, external information, or user explanation, finish the task, explain the evidence and concrete proposed changes, and ask whether to update the skill. Apply changes only after the user's affirmative reply. Routine discoveries from a few attempts do not warrant additions; discovered errors always warrant a correction proposal. Keep updates self-contained, without provenance sections or references to local investigation artifacts.
