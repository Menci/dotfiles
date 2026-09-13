# ACEP2 serialization

## Container

The inspected ACEP2 files contain **zstd-compressed CBOR**. Metadata before the content is opaque and can be skipped when reading the musical project; its purpose remains unverified.

All integers below are little-endian:

| Offset | Type | Meaning |
| --- | --- | --- |
| `0x00` | 5 bytes | `ACEP2` |
| `0x05` | u8 | Flags; observed value `1` |
| `0x06` | u16 | `header_size` field |
| `0x08` | u64 | Content offset |
| `0x10` | u64 | Compressed content length |
| `0x18` | u64 | Decompressed content length |
| `0x20` | u16 | Metadata length `N` |
| `0x22` | `N` bytes | Opaque metadata |
| `0x22 + N` | u8 | Metadata flag; observed value `1` |
| `0x23 + N` | 16 bytes | `content_hash` field |
| `0x33 + N` | bytes | Padding to content offset |
| Content offset | bytes | zstd frame containing CBOR |

Use the declared content offset rather than a fixed header length. The field called `content_hash` is 16 bytes; its algorithm remains unverified.

```python
import struct
import cbor2
import zstandard

if data[:5] != b"ACEP2":
    raise ValueError("Expected an ACEP2 container")
offset, compressed_size, raw_size = struct.unpack_from("<QQQ", data, 8)
raw = zstandard.ZstdDecompressor().decompress(
    data[offset:offset + compressed_size], max_output_size=raw_size,
)
if len(raw) != raw_size:
    raise ValueError("ACEP2 content length mismatch")
project = cbor2.loads(raw)
```

Older `.acep` files can use a **JSON envelope** with `compressMethod`, `debugInfo`, `salt`, `version`, and base64 `content`; some envelope versions require decryption before zstd/JSON decoding. Non-ACEP2 files need the matching envelope decoder, not the binary layout above.

## Writing limits

A known CBOR serialization recipe encodes the project dictionary, compresses it with zstd, writes both lengths, and creates an ACEP2 header with `header_size = 0`, content offset `192`, 138 zero metadata bytes, and a zero 16-byte hash. These are writer-specific choices, not container requirements; application-generated headers can differ.

Decoding is verified, but application acceptance of newly written ACEP2 metadata remains unverified. An encode/decode round trip alone does not establish that acceptance. Preserve the full decoded document when editing an existing project: a converter's narrower intermediate song model can discard fields outside its supported conversion scope.
