---
name: synthesizer-v
description: Directly parse, edit, generate, or convert Synthesizer V 1 and 2 SVP project files, including group references, phoneme timing, and version-specific serialization.
---

# Synthesizer V project files

These format details cover inspected SV1 v153 and SV2 v196 files. Version numbers identify the observed schemas, not a complete compatibility matrix.

## Container, references, and time

- SVP is JSON. Inspected v153 files end in a NUL byte; inspected v196 files do not. Strip trailing NUL bytes for parsing and preserve the source file's convention when editing. For a v153 writer, emit the observed trailing NUL.
- A track has both its own `mainGroup`/`mainRef` pair and `groups[]` references into `library[]`. Resolve each `groups[].groupID` against `library[].uuid`; `mainRef.groupID` identifies the track's own `mainGroup.uuid`. An empty `mainGroup.notes` does not imply an empty track. Unreferenced library groups do not contribute notes.
- One quarter note is **705600000 blicks**. A note instance's global onset is `note.onset + reference.blickOffset`; its effective MIDI pitch is `note.pitch + reference.pitchOffset`. Offsets can be negative. Apply the reference offset exactly once when flattening a group.
- For v196, identify a placed note by **reference UUID + note UUID**. A library note can appear through multiple references, so its note UUID alone does not identify a timeline instance. Saving split or merged edits can replace note UUIDs; later reconciliation also needs the original note geometry and mapping.
- Group moves can change global timing while leaving every note's local onset and duration untouched. Compare both coordinate systems before applying a correction. Saving can discard unused library groups, so persistent helper-note snapshots may need storage outside the SVP.
- `lyrics` and `phonemes` are separate: an empty `phonemes` string requests generated pronunciation; it does not mean silence. `attributes.phonemes[]` stores per-phone controls and is not the pronunciation string. Empty controls do not reveal automatically generated phone boundaries.

## Phoneme edits and conversion

Read [phoneme timing](references/phoneme-timing.md) for SV2 `leftOffset`, language-specific phone encoding, adjoining syllables, and existing automatic timing caches. **`leftOffset` is seconds relative to the note onset**, not an additional displacement from the automatic boundary.

Read [SV1 serialization](references/sv1.md) when generating v153 files or converting SV2 phoneme timing into note boundaries. A version-number change alone does not convert the schema. SV1 explicit-phone continuation fragments require blank lyrics in the validated conversion; `lyrics: "-"` with an explicit `phonemes` value produced silence.

## Skill maintenance

If this skill contains an error, or a task yields worthwhile missing knowledge learned through substantial investigation, external information, or user explanation, finish the task, explain the evidence and concrete proposed changes, and ask whether to update the skill. Apply changes only after the user's affirmative reply. Routine discoveries from a few attempts do not warrant additions; discovered errors always warrant a correction proposal. Keep updates self-contained, without provenance sections or references to local investigation artifacts.
