---
name: melodyne
description: Parse Melodyne .mpd project files directly to extract linked note, source-audio, and arrangement data using the empirically recovered Melodyne 5 object graph.
---

# Melodyne project data

The recovered format covers reading Melodyne 5 `.mpd` documents. Read [the graph reference](references/mpd-graph.md) when implementing a parser. Binary writing and application acceptance of rewritten MPDs remain unverified.

## Keep three representations separate

| Representation | Fields | Units / meaning |
|---|---|---|
| Musical grid | `MUNote.startQuarter`, `endQuarter`, `pitchIndex` | Quarter positions are signed numerator/denominator pairs; observed `pitchIndex = 0` corresponds to MIDI 60. |
| Arrangement element | `MUElement.startTime`, `duration`, `pitchCenter` | Project seconds; pitch in cents, so `pitchCenter / 100` is fractional MIDI pitch. |
| Source detection | Linked source item's `startSampleIndex`, `sampleCount`, `pitchCenter` | Source sample positions/counts; pitch also in cents. |

Join musical notes through object references:

```text
MUElement.noteRealization -> MUNoteRealization.note -> MUNote
```

The object ID is the join key. Serialization write order differs from ID order. A blanket extraction of every `MUElement` includes residual detections; `isResidual = true` can coexist with `detectionQuality = 1.0`. Carry these source-item fields with the extracted record. Quality alone does not select musical notes.

## Resolve source time through the audio link

```text
MUElement.principalAudioComponent
  -> MUAudioComponent.audioSourceComponent
  -> MUAudioSourceComponent.audioSourceItem
  -> MUAudioSourcePrincipalItem

sourceItem.audioSourceDescription
  -> MUAudioSourceDescription.audioSource
  -> MUAudioFileSource.sampleRate
```

For files whose file-source `startSampleIndex = 0` and `sampleOffset = 0`, the following source-interval calculation has been verified:

```python
source_time = source_item["startSampleIndex"] / audio_source["sampleRate"]
source_duration = source_item["sampleCount"] / audio_source["sampleRate"]
project_placement_offset = element["startTime"] - source_time
```

Use each linked source's sample rate. An exact serialized-class lookup must use `MUAudioFileSource` for those file-source objects; a lookup for the base name `MUAudioSource` can return none.

Arrangement seconds and source-audio seconds can differ by a placement offset, including different offsets for lead and harmony documents of the same song. Determine the offset from the linked records rather than assuming the paired files share a time origin.

`MUElement.sourceTimeForElementTimeFunction` links to a `MUBezierDataPointFunction` with `MUBezierFunctionPoint` objects. Nonidentity point mappings can exist even when element/source durations match. The formulas above do not define arbitrary edited time warps. Keep source `pitchCenter`, element `pitchCenter`, and score `pitchIndex` separate as well: equality of the centers in unaltered data does not establish the complete rendered-pitch edit model.

## Skill maintenance

If this skill contains an error, or a task yields worthwhile missing knowledge learned through substantial investigation, external information, or user explanation, finish the task, explain the evidence and concrete proposed changes, and ask whether to update the skill. Apply changes only after the user's affirmative reply. Routine discoveries from a few attempts do not warrant additions; discovered errors always warrant a correction proposal. Keep updates self-contained, without provenance sections or references to local investigation artifacts.
