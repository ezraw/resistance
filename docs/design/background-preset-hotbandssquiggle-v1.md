# Reusable Background Preset: HotBandsSquiggle v1

## Canvas and Layout

Portrait mobile screen.

Background is built from stacked horizontal color bands plus a fixed squiggle motif across the upper third.

All blending between bands uses ordered pixel dithering.

## 8-Color Palette

| Name | Hex |
|------|-----|
| Hot pink | #F21695 |
| Magenta | #DE1070 |
| Purple-magenta | #9E0EAB |
| Electric violet | #6A0FC6 |
| Deep violet | #5609B1 |
| Night plum | #29045C |
| Neon cyan | #2BD1C2 |
| Warm cream | #FCEED0 |

## Band Map (by vertical percentage)

| Range | Description |
|-------|-------------|
| 0% to 28% | Base #F21695 with light peppering of #DE1070 |
| 28% to 44% | Transition zone, ordered dither between #F21695 and #DE1070 |
| 44% to 62% | Base #DE1070 |
| 62% to 76% | Transition zone, ordered dither between #DE1070 and #6A0FC6 |
| 76% to 92% | Base #6A0FC6 shifting toward #5609B1 via a second dither strip |
| 92% to 100% | Base #5609B1 with pockets of #29045C |

## Dither Rules

- **Pattern**: Bayer ordered dither (4x4)
- **Transition strip height**: 6% to 10% of screen height per transition
- **Dither mix**: 50/50 at strip center, tapering toward each band edge

## Pixel Noise and Particles

- **Density**: 2% to 4% of pixels occupied by particles across the full screen
- **Particle types**: single pixels and 2x2 blocks
- **Color distribution**:
  - 60% #DE1070
  - 25% #6A0FC6
  - 10% #5609B1
  - 5% #2BD1C2
- Particles are slightly denser from 60% down to the bottom

## Fixed Squiggle Motif

- **Placement**: centered horizontally, spanning 90% to 95% of screen width
- **Vertical position**: centered at ~22% screen height
- **Shape**: keep the same silhouette, stroke thickness, and stepped pixel corners as the reference image
- **Colors**:
  - Main stroke: #2BD1C2
  - Secondary stroke: #FCEED0
- **Construction**: straight pixel-step segments, no curves

## Copy-Paste Prompt Snippet for Reuse

```
Use the HotBandsSquiggle v1 background preset: 8-color palette only
(#F21695 #DE1070 #9E0EAB #6A0FC6 #5609B1 #29045C #2BD1C2 #FCEED0).
Stacked horizontal bands with Bayer 4x4 ordered dithering between bands,
plus low-density pixel noise particles. Keep the cyan/cream cup-style
squiggle exactly as in the reference, same placement and shape, built
from pixel steps.
```
