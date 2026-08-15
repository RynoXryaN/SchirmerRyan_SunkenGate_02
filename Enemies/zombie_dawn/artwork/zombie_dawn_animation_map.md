# Zombie Dawn animation map

Prepared from the original atlas without resampling or recoloring. Only the exact background colors `#00FF00` and `#008080` were converted to alpha in working assets.

| Animation | Frames | Timing (ms) | Loop | Confidence |
|---|---:|---|---|---|
| `rise` | 8 | 140, 140, 140, 140, 140, 140, 140, 140 | no | high |
| `shamble` | 8 | 180, 150, 170, 210, 180, 150, 170, 210 | yes | high |
| `uncertain_pose` | 1 | 180 | no | low; possibly an attack, hurt, or alternate shamble pose |

## Layout

- Frame canvas: `32 × 48` px
- Ground line: `y = 44`
- Recommended pivot/origin: `(16, 44)` from the frame top-left
- Recommended Godot offset with a centered 32×48 region: `(0, 20)`
- Sheet grid: 8 columns × 3 rows; unused grid cells are transparent

## Classification notes

- `rise`: top-row progression from a ground slit to a complete standing zombie; order follows increasing visible body height.
- `shamble`: second-row full-body cycle in left-to-right source order. Frames use a shared ground line and centered source bounds to suppress atlas-placement jitter while retaining intended limb motion.
- `uncertain_pose`: isolated third-row full-body pose. It may be an attack, hurt, or alternate walk pose; it is deliberately not merged into a confident gameplay animation.
- Source region `(0,288)–(256,464)` contains tightly packed dismembered parts, gore, guide pixels, and palette swatches. It is shown in the contact sheet and retained in the unchanged source reference, but no unsupported death/disintegration order was invented.

## Validation

- Every extracted frame has a SHA-256 digest of its non-transparent RGBA pixel multiset in the JSON; placement validation confirms those pixels are unchanged.
- Both confirmed background colors are absent from the working frames and replaced by alpha.
- Every frame fits inside its standardized canvas with no clipping.
- GIF previews are scaled 4× with nearest-neighbor resampling.
- The source reference is a byte-for-byte copy; its SHA-256 is recorded in JSON.
