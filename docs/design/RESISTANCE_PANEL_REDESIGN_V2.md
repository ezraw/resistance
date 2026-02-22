# Resistance Panel Redesign v2 — Plan

## Status: READY TO IMPLEMENT

Reference image: `/Users/ezrawolfe/temp/Screenshot 2026-02-22 at 10.51.56 AM.png`
Current (broken): `/Users/ezrawolfe/Downloads/Screenshot 2026-02-22 at 10.39.00.png`

---

## Measurements from Reference Image

### Panel
- Width: ~84% of screen width (current side padding of 16px is fine)
- Height: ~53% of screen — panel sits between badges and START button with clear gaps
- Top gap: ~15% of screen between badges and panel top edge
- Bottom gap: ~10% between panel bottom edge and START button
- Border: THICK — visually about **8px** (current 6px is too thin)
- Corners: very rounded, 3+ stair steps
- Outer padding needed: **top: 56, bottom: 80, sides: 16**

### Arrows — THE KEY CHANGE
The reference arrows are **wide, chunky, stair-stepped pixel-art shapes**:
- Fill about **45-50%** of the panel interior width
- Wider than tall (landscape orientation, NOT square)
- Arrowhead is a stair-stepped triangle with **all 90-degree edges** (no diagonals!)
- Each stair step expands by 1 block on each side
- Shaft is about **60%** of arrowhead base width
- Arrowhead is about **70%** of total arrow height, shaft is **30%**
- Dark orange shadow on bottom edge (1 block unit thick) for 3D raised look
- Gold (#FFD700) body, goldDark (#CC9900) shadow for up, burntOrange (#CC6600) for down

### Proposed Arrow Shape (UP ARROW on 10×7 block grid)

```
Col:  0  1  2  3  4  5  6  7  8  9
R0:   .  .  .  .  ██ ██  .  .  .  .    tip: 2 blocks
R1:   .  .  .  ██ ██ ██ ██  .  .  .    4 blocks (+1 each side)
R2:   .  .  ██ ██ ██ ██ ██ ██  .  .    6 blocks (+1 each side)
R3:   .  ██ ██ ██ ██ ██ ██ ██ ██  .    8 blocks (+1 each side)
R4:   ██ ██ ██ ██ ██ ██ ██ ██ ██ ██   10 blocks (full width = arrowhead base)
R5:   .  .  ██ ██ ██ ██ ██ ██  .  .    shaft: 6 blocks (60% of base)
R6:   .  .  ██ ██ ██ ██ ██ ██  .  .    shaft
```

DOWN ARROW (vertically mirrored):
```
Col:  0  1  2  3  4  5  6  7  8  9
R0:   .  .  ██ ██ ██ ██ ██ ██  .  .    shaft: 6 blocks
R1:   .  .  ██ ██ ██ ██ ██ ██  .  .    shaft
R2:   ██ ██ ██ ██ ██ ██ ██ ██ ██ ██   10 blocks (full width)
R3:   .  ██ ██ ██ ██ ██ ██ ██ ██  .    8 blocks
R4:   .  .  ██ ██ ██ ██ ██ ██  .  .    6 blocks
R5:   .  .  .  ██ ██ ██ ██  .  .  .    4 blocks
R6:   .  .  .  .  ██ ██  .  .  .  .    tip: 2 blocks
```

Properties:
- Aspect ratio: **10:7** (wider than tall)
- Arrowhead: 5 rows (71% of height)
- Shaft: 2 rows (29% of height)
- Shaft width: 6/10 = 60% of base
- All edges are 90-degree right angles (stair-stepped, no diagonals)

### Shadow rendering
- Draw shadow shape offset **1 block unit down**
- Then draw gold body shape on top
- Shadow peeks out on bottom edge creating 3D raised look
- Up arrow shadow: AppColors.goldDark (#CC9900)
- Down arrow shadow: AppColors.burntOrange (#CC6600)

### Sizing
Target: 45% of panel interior width.
- Screen ~390px → panel interior ~306px → arrow width ~138px
- With 10 blocks: each block = ~14px
- Arrow height = 7 × 14 = ~98px
- Use `LayoutBuilder` to size dynamically: `width = constraints.maxWidth * 0.45`
- Height derived from aspect ratio: `height = width * 7/10`

### Dividers
- Thickness: **3px** (up from 2px)
- Color: purpleMagenta (unchanged)
- Position: **immediately adjacent to the number** (6px gap from number)
- Large gap between divider and arrows (~spacer fills remaining space)
- Run full panel interior width (margin: 0, not 8)
- The dip/arc effect is subtle and fine to keep

### +5 / -5 Badges
- Small centered badge at very top / bottom of each half
- Gold border, transparent fill, gold text
- Existing implementation is fine
- -5 badge may not be visible in this reference but include it for symmetry

### Number
- Large white pixel font (current is fine)
- Centered between the two dividers
- Current font size logic is fine (48pt at 100, 64pt otherwise)

---

## Layout Structure (inside panel)

```
ArcadePanel(steps: 3, borderWidth: 8, borderColor: magenta)
  padding: vertical=12, horizontal=16
  Column:
    Expanded (top half — GestureDetector increase)
      Column(mainAxisAlignment: center):
        Spacer
        +5 badge
        SizedBox(height: 12)
        ResistanceArrow(direction: up, widthFraction: 0.45)
        Spacer       ← pushes arrow UP, away from divider

    PixelDivider(thickness: 3, margin: 0)   ← right above number
    SizedBox(height: 6)
    AnimatedBuilder [number with pulse]
    SizedBox(height: 6)
    PixelDivider(thickness: 3, margin: 0)   ← right below number

    Expanded (bottom half — GestureDetector decrease)
      Column(mainAxisAlignment: center):
        Spacer       ← pushes arrow DOWN, away from divider
        ResistanceArrow(direction: down, widthFraction: 0.45)
        SizedBox(height: 12)
        -5 badge
        Spacer
```

Key difference from current: dividers are OUTSIDE the Expanded halves, right next to the number. The Spacers inside Expanded push the arrows AWAY from the dividers (toward the badge end).

---

## Implementation Steps

### Step 1: Create `ResistanceArrow` widget

**New file:** `lib/widgets/arcade/resistance_arrow.dart`

```dart
enum ArrowDirection { up, down }

class ResistanceArrow extends StatelessWidget {
  final ArrowDirection direction;
  final Color color;          // default: AppColors.gold
  final Color shadowColor;    // default: AppColors.goldDark
  final double widthFraction; // default: 0.45 (fraction of parent width)

  // Uses LayoutBuilder to determine width from parent
  // Height = width * 7/10 (aspect ratio)
  // Each block = width / 10
  // Shadow drawn offset 1 block down
  // Body drawn on top
  // All stair-step right-angle edges (no diagonals)
}
```

The painter draws the shape using `Path` with only `lineTo` commands (horizontal and vertical lines). The path traces the stair-step outline of the arrow.

### Step 2: Update `ResistanceControl` layout

**File:** `lib/widgets/resistance_control.dart`

- Change outer padding: `top: 56, bottom: 80, sides: 16`
- Change ArcadePanel: `borderWidth: 8` (was 6)
- Move dividers outside Expanded (adjacent to number)
- Replace `PixelIcon.upArrow(size: 72)` with `ResistanceArrow(direction: up)`
- Replace `PixelIcon.downArrow(size: 72)` with `ResistanceArrow(direction: down)`
- Change PixelDivider: `thickness: 3, margin: 0`
- Restructure Column so dividers are between Expanded halves and number

### Step 3: Update tests

- Update widget_test.dart: find `ResistanceArrow` instead of `PixelIcon`
- Test arrow directions present
- Test tap behavior still works
- Test disabled opacity

### Step 4: Update docs and changelog

- Update CHANGELOG.md v0.6.5 entry
- Update STYLE_GUIDE.md with arrow specs

---

## What's Already Done (Keep)

- `buildPixelBorderPathMultiStep()` ✅
- `steps` parameter in painter/container/panel ✅
- `AppColors.burntOrange` ✅
- `PixelDivider` widget (adjust defaults) ✅
- GestureDetector zones ✅
- Opacity-based disabled state ✅
- Pulse animation ✅

---

## Files to Modify

| File | Change |
|------|--------|
| `lib/widgets/arcade/resistance_arrow.dart` | **New** — dedicated wide stair-step arrow |
| `lib/widgets/resistance_control.dart` | Layout restructure: new arrows, divider position, padding, border |
| `test/widget_test.dart` | Update for ResistanceArrow |
| `CHANGELOG.md` | Update v0.6.5 entry |
| `docs/design/STYLE_GUIDE.md` | Document arrow specs |

---

## Verification

1. `flutter analyze` — zero issues
2. `flutter test` — all pass
3. Visual comparison with reference image:
   - [ ] Arrows are wide stair-stepped shapes filling ~45% of panel width
   - [ ] Arrows are wider than tall (landscape, not square)
   - [ ] Arrows have visible stair-step edges (no diagonals)
   - [ ] Arrows have 3D shadow on bottom edge
   - [ ] Dividers are right next to the number (not near the arrows)
   - [ ] Dividers run full panel width, 3px thick
   - [ ] Panel border is visibly thick (8px)
   - [ ] Panel does not overlap badges or START button
   - [ ] Clear gap above and below the panel
   - [ ] +5 badge at top, -5 badge at bottom
   - [ ] Tapping works in both halves
   - [ ] Disabled opacity at 0%/100%
