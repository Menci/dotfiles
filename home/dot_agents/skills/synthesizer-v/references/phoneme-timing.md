# SV2 phoneme timing and pronunciation

## Written boundaries

In the tested v196 schema, `attributes.phonemes[i].leftOffset` is the phone's start in **seconds relative to that note's onset**. Negative values place a consonant before the note. It is not a delta added to the automatic phone boundary.

For a syllable delayed by `delta` seconds and a single initial consonant of duration `head`:

```text
initial.leftOffset = delta - head
nucleus.leftOffset = delta
```

An omitted offset leaves that phone boundary automatic. It cannot be interpreted as a measured zero. Reconstruct a phone's end from the following boundary, not from `leftOffset` alone.

In a continuous phrase, the following syllable's initial can occupy the preceding note's final portion. To retain a known coda duration after changing that initial, place the coda relative to the new audible endpoint:

```text
codaStartRelativeToCurrentNote = nextInitialStartGlobal - currentNoteStartGlobal - codaDuration
```

This formula applies to adjoining syllables; real rests and detached endings require their actual boundaries. Moving whole note onsets to encode small syllable delays can introduce short rests and change consonant allocation. Writing the nucleus offset can express that delay while preserving adjoining notes.

## Transferring timing between tracks

Time-aligned tracks often need one's timing and pronunciation copied onto another. Nothing in the file records the correspondence: group and reference UUIDs are per-lane and a note carries no back-reference, so the pairing is positional — resolved from where notes sound, with lane names indicating intent at best.

Two things hold generally; neither has a fixed rule.

- **The unit that moves is the source's syllable, not its note.** One syllable is commonly spread over several notes joined by `-` continuation notes. Group the source's notes into syllables before comparing spans. Measuring a destination note against the single source note under its onset invents a mismatch on every split syllable, and makes a short note look like it should be a longer one.
- **The destination's own division is not authoritative and is expected to be overridden.** The same music is cut into different numbers of notes between projects and between programs: one inspected part needed 18 cuts against one program's division of its source material and 25 against the other's, for the same 217 destination notes and the same 174 covered. Derive the destination's division from the source's structure rather than preserving what is already there.

The remaining cases follow from onset and context rather than from a rule: a destination note may enter late inside a syllable, cover only part of one, or cover two.

Division is the only structural change. Everything not being transferred — pitch, detune, accent, takes, and the destination note's own attributes — is carried onto each resulting piece unchanged, and a piece cut at its origin's onset keeps that origin's UUID. A destination note the source does not sound under keeps what it had.

Pronunciation copies verbatim: `leftOffset` is already seconds relative to the note onset, so a piece shorter than its source keeps the source's real consonant duration rather than a recomputed one. Deriving offsets from a ratio between the two notes is wrong.

## Phone symbols and language scope

- Store explicit pronunciation in `note.phonemes`, separated by spaces. Per-note language override belongs in `note.attributes.languageOverride` and `phonesetOverride`, not at note top level or inside each entry of `attributes.phonemes[]`.
- Observed language/phoneset pairs are `mandarin`/`xsampa`, `english`/`arpabet`, and `japanese`/`romaji`. Language resolves from the note override, then the reference's database override, then the database's native language.
- A symbol's acoustic meaning depends on its language. Mandarin `u` and Japanese `u` are not interchangeable. A deliberate `[i M N]` realization of `ing` requires a Japanese-language `u` fragment for `[M]`. Apply this construction only when it is the intended pronunciation.
- The Mandarin dictionary separates finals that ACE may encode as one phone: `xing` → `s\ i N`, `bian` → `p iE :n`, `sui` → `s ue :\i`. Select migration cases from resolved phone sequences, not just Latin lyric suffixes: `yan`-family syllables can use the same `iE :n` structure as `ian`.
- The inspected SV pronunciations for `yi`, `yv`, and `wu` lacked an initial. To preserve an initial explicitly added in a source project, use `j i`, `j y`, or `w u` as appropriate.
- App resources `clf-data/mandarin-xsampa-dict.txt`, `mandarin-xsampa-phones.txt`, and `cedict.txt` supply phone sequences, types, and candidate readings. Some Chinese characters have ambiguous dictionary readings; dictionary lookup alone cannot recover an intended pronunciation override.

## Existing automatic timing cache

Automatic duration output was found in SV2 **project-level** LMDBs:

```text
<SV2 application-support>/cache/<cache-id>/<cache-id>.lmdb
key: n_<hash>
value: JSON
```

Neighboring `g_*.lmdb` group caches contain audio/tensor records. Cache directory IDs do not reliably equal project SVP UUIDs.

| JSON path | Meaning |
| --- | --- |
| `record["7"]` | `[noteOnsetSeconds, noteEndSeconds]` |
| `record["8"]` | MIDI pitch |
| `record["5"]` | Array containing one note in inspected records |
| `record["5"][0]["a"]` | First-phone offset from note onset, seconds |
| `record["5"][0]["6"]` | Phone array |
| `phone["a"]`, `phone["b"]`, `phone["c"]` | Symbol, language, duration in seconds |

For a complete record, phone `i` starts at `record["7"][0] + record["5"][0]["a"] + sum(previous phone durations)`. Retain the stored first-phone offset: it does not always equal the negative duration of the first consonant.

Inspected durations lie on a **5 ms grid**. Some phone entries omit duration and therefore do not provide a complete layout. These records contain **automatic layouts**; handwritten `leftOffset` values are not already applied to them.

A matching phone sequence, note length, and pitch does not uniquely identify a layout. Including total phone duration still leaves ambiguous matches. The inspected records do not identify the voicebank. Retain the originating cache, note time, language, and context when matching; a lookup pooled across projects or a fitted model is not an exact result for another note or voice. Coda duration is neither universally constant nor a fixed fraction of the available interval.
