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

### Transferring timing and pronunciation between tracks

Time-aligned tracks often need one's timing and pronunciation copied onto another. A note carries no back-reference to its counterpart, so the pairing is positional — resolved from where notes sound, with track names indicating intent at best.

The unit that moves is the source's **syllable**, spelled in ACE as a run of ordinary notes each holding one language and one phone group; group those runs before comparing spans. Measuring a destination note against the single source note under its onset invents a mismatch on every such run. The destination's own division is not authoritative and is expected to be overridden — the same music is cut into different numbers of notes between projects and between programs — so derive it from the source's structure rather than preserving it. The remaining cases follow from onset and context rather than from a rule: a destination note may enter late inside a syllable, cover only part of one, or cover two.

Cut a destination note at the run's own note boundaries and give each piece the matching source note's `lyric`, `language`, `syllable`, `freezedDefaultSyllable`, `headConsonants` and `tailConsonants` whole. Those durations are already seconds, so a piece shorter than its source keeps the real consonant length rather than a recomputed one. Everything else — onset, duration, pitch, and the note's other fields — stays as it was, and a destination note the source does not sound under keeps what it had.

ACE's phone inventory is its own and does not correspond symbol-for-symbol to another program's encoding of the same audio, and its consonant durations come from a model rather than a derivable formula. A translation table between one program's phoneme data and another's does not exist; transfer within one program.

### Stored tail duration is not an absolute boundary

Extending the next note's leading consonant can move the preceding coda. Consequently, `note_end - sum(tailConsonants)` does **not** reconstruct every effective coda onset. Explicitly split nasal-bearing notes can provide the intended segmentation for a migration, but that does not establish a general renderer formula. Keep stored durations, note segmentation, and effective boundaries distinct; a context-free extraction is not exact rendered phoneme alignment.

## Parameter data

`pattern.parameters` contains segment lists, including `pitchDelta`, `energy`, `gender`, `breathiness`, `tension`, and `real*`/`mamba*` lanes. A `type: "data"` segment has `offset` and `values`, sampled once per tick. A `type: "anchor"` segment stores a **flat** `points` array `[tick, value, tick, value, ...]`; the recovered conversion uses Hermite interpolation. Preserve the representation and unfamiliar lanes when making unrelated edits.

### `pitchDelta` is measured against a smoothed reference, not against the note pitch

`pitchDelta` is note-relative: the rendered pitch at tick `t` is `note.pitch + pitchDelta[t]`. The renderer, however, does not add the owning note's pitch back as a step. It adds a **continuous reference track** `P`:

- Partition the timeline at the **midpoint of the region between consecutive notes**, measured between their sounding spans: `(prev.pos + prev.dur + cur.pos) / 2`.
- `P` is the pitch of the note on the near side of each partition point.
- Smooth every partition point with a **raised cosine** of half-width **60 ms**, converted to ticks as `0.06 * bpm / 60 * 480` (about 57.6 ticks at 120 BPM, 77.3 at 161 BPM):

```
P(pos+d) = ip + (ic - ip) * (1 - cos(pi (d + W) / (2W))) / 2      |d| <= W
```

`ip` and `ic` are the two neighbouring pitches and `d` runs from the partition point. The result is a portamento: flat inside notes, joined by a C1-continuous S-curve whose transition passes through the centre of the inter-note region in **both** axes — time at the midpoint, pitch at the mean of the two. It is independent of consonants, note lengths, and interval size, so the transition width is a fixed duration rather than a fixed number of ticks.

To make ACE render an absolute target curve `D(t)`, write `pitchDelta[t] = D(t) - P(t)`. Subtracting the owning note's pitch instead is correct on the note's plateau but wrong by a whole interval within `+/-W` of every partition point; where the reference has already moved on before a note begins — a note after a rest, whose leading consonants lie past the partition point — the error reaches the full interval.

Two calibration techniques read `P` back out of a file: set the entire lane to a single constant and ACE draws `P` itself, shifted by that constant; or have a user draw a flat line at a known absolute height `C`, so that `P(t) = C - pitchDelta[t]`. A line drawn inside one note cannot distinguish this model from a step, because the two agree on a plateau; the discriminating sample is a line that crosses a note boundary.

### Voicing is a renderer decision, not authored data

`vuv` (1.0 voiced, 0.0 unvoiced) is derived by ACE at render time rather than by the user's editing gesture: the same phoneme can come out dashed or solid depending on how long it is, so a stored `vuv` is a cache of one rendering decision, not a property of the note. `pitchDelta` is a subset of `vuv` — the pitch lane only carries samples where the voice is voiced.

When writing, **keep the existing dashed/solid pattern wherever it already exists**; do not recompute voicing from `headConsonants`, `tailConsonants`, or phoneme identity. Supplying `vuv = 1.0` for genuinely new ticks is the only safe extension.

## Skill maintenance

If this skill contains an error, or a task yields worthwhile missing knowledge learned through substantial investigation, external information, or user explanation, finish the task, explain the evidence and concrete proposed changes, and ask whether to update the skill. Apply changes only after the user's affirmative reply. Routine discoveries from a few attempts do not warrant additions; discovered errors always warrant a correction proposal. Keep updates self-contained, without provenance sections or references to local investigation artifacts.
