# Reusable water regions

Drag `StreamingWater2D.tscn` or `StandingWater2D.tscn` into a 2D level. Resize with the root `Region Size` property, or select its `CollisionShape2D` and drag the rectangle handles. For streaming water, the rectangle is the maximum reach: at runtime the stream begins at its top edge and ends at the nearest water, ground, Player, or Enemy collision.

Streaming water includes a compact authored pixel-art tile combined with a pixel-snapped layered shader. Standing water keeps the same resizeable Area2D workflow and renders as transparent gothic water: a roughly 40% body tint with restrained depth darkening, optional subtle shimmer, and sparse bubble clusters. It intentionally has no separate surface layer. Player and Enemy bodies receive a reversible underwater tint while overlapping the region.

Player mouth bubbles are lightweight scripted sprites. The breath component passes them the active standing-water surface height, and each bubble removes itself when it reaches that height. This keeps their curved, randomized motion while avoiding particle-collision nodes that are unavailable in Godot 4.7.

Resizing changes how many 64-pixel tiles are shown; it does not enlarge the artwork. Streaming water also exposes `Origin Shape` (`Circle` or `Rounded Rectangle`), `Origin Depth`, and `Origin Corner Radius`. These shape the top of the visible stream without changing its rectangular collision width.

Standing water detects Player bodies on layer 5. Each stream uses a downward shape cast against Ground, Player, Enemy, and the dedicated `WaterInteraction` layer 9. It creates one continuous impact emitter at the nearest hit; Player and Enemy hits use the configurable `Character Impact Multiplier`. Player movement uses cooldown-controlled one-shot emitters and does not modify the Player script.

Rectangular intersection assumes unrotated water regions. Use `Flow Direction` for visual direction instead of rotating the region when automatic surface impacts are needed.
