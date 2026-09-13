# Recovered MPD graph layout

This is an empirical reading model for inspected Melodyne 5 files, not a complete serialization specification.

## Outer file and graph

The outer signature is ASCII `GNBCFA`. Inspected files contained separate zlib streams beginning with bytes `78 5e`; the largest decompressed stream was the object graph, and the smaller one held metadata. Neither a fixed byte offset nor that one zlib header is a universal format guarantee.

The graph uses little-endian integers and this layout:

```text
u32 string_count
repeat string_count:
    u32 byte_length
    byte[byte_length] name

u32 class_count
repeat class_count:
    u32 class_name_byte_length
    byte[class_name_byte_length] class_name
    u32 class_version
    u32 member_count
    repeat member_count:
        u32 member_name_string_index
        u32 count
        u32 type_id
        u8 flags

u32 object_count
u32[object_count] class_index_by_object_id
u32 write_order_count
u32[write_order_count] object_ids_in_write_order

repeat write_order_count:
    u32 payload_byte_length
    byte[payload_byte_length] payload
```

Payloads begin with a `u32` per-object version, followed by declared members in order. Class version and per-object version are distinct fields. Ordinary decoded note/element payloads left eight trailing bytes after the members. Preserve that opaque remainder; container payloads have additional data and cannot all be treated as ordinary fixed records.

| Type ID | Width | Observed decoding |
|---|---:|---|
| `0x162` | 1 | Boolean byte |
| `0x466` | 4 | IEEE float32 |
| `0x469` | 4 | Signed int32 |
| `0x85e` | 8 | Signed int32 object ID, then four additional bytes; ID `-1` is nil |
| `0x864` | 8 | IEEE float64 |
| `0x86c` | 8 | Signed int64 |
| `0x871` | 8 | Two signed int32 values: numerator and denominator, used for quarters |

Provisional decoders have treated `0x163` as a one-byte Boolean and `0x1052` as an eight-byte double; their semantics remain unconfirmed. Unknown type widths, member `count`, flags, reference suffixes, and opaque payload data remain relevant when extending a reader or attempting a writer.

## Containers and strings

Fixed members and reference traversal are better established than the container payload layout:

- A provisional container decoder skips five `u32` words after declared members and treats the fifth as a data length. Some lengths exceed the available payload; the reason is unresolved. Clamping the length can allow partial extraction but does not establish a lossless interpretation.
- For `GNList`, a successful decoding pattern reads `u32` words and strips the first word when it equals the remaining word count. Treating every word as an ID when this check fails is an unverified heuristic, not an established second encoding.
- For `GNString`, the declared schema member `encoding` selects decoding: observed `5` means UTF-16LE and `0` uses UTF-8/ASCII. Taking encoding from the presumed container-data prefix can damage text. Subtracting an unconditional eight-byte trailer can truncate strings.

Successful note extraction does not validate every container or lossless serialization. A writer must resolve the unknown payload details instead of discarding bytes through clamping or assuming the raw-ID heuristic is authoritative.
