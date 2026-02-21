# Resistance App — Design Style Guide

This is the authoritative style guide for the Resistance app. All UI work —
planned or unplanned — MUST follow these rules. When in doubt, refer to the
mockup reference images in `docs/design/` and the principles below.

---

## 1. Design Philosophy

The app uses a **retro pixel-art arcade game aesthetic** rooted in kidcore /
Y2K culture, rendered as a mobile fitness app. The vibe is a colorful 16-bit
arcade cabinet — bold, playful, energetic. Every screen should feel like a
level in a game, not a utilitarian settings panel.

**Core principles:**
- Bold over subtle. If a color can be saturated, saturate it.
- Everything has weight. Buttons have 3D depth. Panels have borders. Elements feel physical.
- Motion is purposeful. Animations reinforce actions, never distract from the workout.
- Consistency is non-negotiable. Every panel, button, and badge follows the same construction rules regardless of screen.

---

## 2. Color Palette

The app uses a strict 8-color palette. Do NOT introduce colors outside this set.
Tints and shades are achieved through dithering and opacity, not by picking new hex values.

| Token | Name | Hex | Usage |
|-------|------|-----|-------|
| `hotPink` | Hot pink | #F21695 | Background bands (top), highlights |
| `magenta` | Magenta | #DE1070 | Background bands (mid), panel borders, active accents |
| `purpleMagenta` | Purple-magenta | #9E0EAB | Transitions, secondary accents |
| `electricViolet` | Electric violet | #6A0FC6 | Background bands (lower), panel fills |
| `deepViolet` | Deep violet | #5609B1 | Background bands (bottom), dark fills |
| `nightPlum` | Night plum | #29045C | Deepest backgrounds, shadow tones |
| `neonCyan` | Neon cyan | #2BD1C2 | Speed streaks, scan elements, cool accents |
| `warmCream` | Warm cream | #FCEED0 | Secondary stroke, light text accents |

**Extended functional colors (derived from palette):**

| Token | Hex | Usage |
|-------|-----|-------|
| `white` | #FFFFFF | Primary text, number displays |
| `gold` | #FFD700 | Buttons (START/DONE), arrows, increment badges |
| `goldDark` | #CC9900 | Button bottom edges, arrow shadows (3D depth) |
| `amber` | #FFBF00 | Warning indicators |
| `green` | #00FF66 | Connected status dot |
| `red` | #FF3344 | Heart icon, disconnect, FINISH button |

### Resistance-Level Color Mapping

The background palette shifts based on resistance intensity. The band structure
stays the same, but the top bands shift warmer as resistance increases:

| Resistance | Top band color | Feel |
|------------|---------------|------|
| 0-20% | Cyan/teal tones | Cool, starting out |
| 25-45% | Hot pink (default) | Warmed up |
| 50-70% | Orange/hot pink | Heating up |
| 75-90% | Deep orange/red | Intense |
| 95-100% | Red/dark red | Maximum, final boss |

The center panel and buttons do NOT change color with resistance — only the
background bands shift. This keeps the controls readable at all intensities.

---

## 3. Background System

Reference: `docs/design/background-preset-hotbandssquiggle-v1.md`

Every screen uses the banded background system. The specific band colors vary
by screen context, but the structure is constant:

### Band Structure
- Stacked horizontal color bands filling the full screen
- All transitions between bands use **Bayer 4x4 ordered dithering**
- Transition strips are 6-10% of screen height
- Dither mix: 50/50 at strip center, tapering toward each band edge

### Pixel Particles
- Present on EVERY screen
- Density: 2-4% of pixels occupied
- Types: single pixels and 2x2 blocks
- Colors drawn from the palette (60% magenta, 25% electric violet, 10% deep violet, 5% neon cyan)
- Denser in the lower (darker) portions of the screen

### Speed Streaks (Squiggle Motif)
- Diagonal cyan (#2BD1C2) and cream (#FCEED0) streaks across the upper third
- Built from straight pixel-step segments (no smooth curves)
- Present on most screens; intensity varies:
  - Idle/low resistance: subtle, fewer streaks
  - Active workout: more numerous, more intense
  - Scan screen: absent (replaced by radar visual)
  - Summary screen: subtle, celebratory

### Screen-Specific Background Variants

| Screen | Top bands | Bottom bands | Streaks |
|--------|-----------|-------------|---------|
| Main (idle) | Hot pink | Deep violet | Standard |
| Main (active) | Orange → hot pink | Deep violet | Intense |
| Main (max resistance) | Red → orange | Dark purple | Maximum |
| Scan | Deep indigo | Night plum | None (radar instead) |
| Summary | Hot pink | Deep violet | Subtle + sparkles |
| Pause overlay | Lavender tint | Deep violet | Subdued |

---

## 4. Typography

### Font Choices
- **Numbers (resistance, timer, HR, stats)**: Bold pixel-style rendering. The
  number should feel chunky and weighty — like stamped arcade score digits.
- **Labels and buttons (START, PAUSE, CONNECTED)**: Bold uppercase, slightly
  condensed. Can be pixel-rendered or a clean bold sans-serif that reads well
  at game-UI scale.
- **Secondary text (helper text, dates)**: Lighter weight, smaller size, in
  warm cream (#FCEED0) or white at reduced opacity.

### Rules
- ALL button labels and headings are UPPERCASE
- Numbers use tabular (monospaced) figures so they don't shift width during animation
- Minimum touch-target text: 14pt equivalent
- Large display numbers (resistance): as large as the panel allows, minimum 60pt equivalent
- Text always white (#FFFFFF) on dark panels, or dark on light buttons

---

## 5. Panels and Containers

Every content grouping uses the standard panel construction:

### Primary Panel (Center Control, Stats, Radar, Device Cards)
- **Fill**: Night plum (#29045C) or dark purple from palette
- **Border**: 6px, color varies by context:
  - Default: Magenta (#DE1070)
  - Cool/low resistance: Neon cyan (#2BD1C2)
  - Hot/high resistance: Orange-red
  - Scan/device cards: Magenta (#DE1070)
- **Corner radius**: 4px (sharp, 8-bit corners)
- **Inner padding**: Generous — content should breathe inside panels
- **Shadow**: None (depth comes from border, not drop shadow)

### Secondary Panel (History rows, badges, sub-sections)
- Same fill as primary but with a thinner 2px border
- Can use magenta or a slightly lighter purple border
- Corner radius: 3px

### Pixel Stair-Step Corners

All arcade containers use 2-step notched staircase corners instead of smooth
`BorderRadius.circular()`. This is implemented via `PixelContainer` which
wraps `PixelBorderPainter` (fill + stroke) and `ClipPath` (child clipping).

| Component | notchSize | borderWidth |
|-----------|-----------|-------------|
| ArcadePanel (primary) | 4 | 6 |
| ArcadePanel (secondary) | 3 | 2 |
| ArcadeButton (all schemes) | 3 | 3 |
| Increment button (+5/-5) | 3 | 3 |
| ArcadeBadge | 2 | 2 |

### Rules for New Panels
- NEVER use a plain rectangle without a colored border
- NEVER use a white or light-colored panel fill
- NEVER use `BorderRadius.circular()` for arcade containers — use `PixelContainer`
- ALWAYS use a palette color for the border
- Panels can be nested (e.g., stats grid inside summary panel) with thinner inner borders

---

## 6. Buttons

All buttons follow the arcade cabinet button construction:

### Primary Button (START, DONE, RESUME)
- **Fill**: Gold gradient (#FFD700 top to #CC9900 bottom)
- **Border**: 3px dark border (night plum)
- **3D depth**: Darker bottom edge (3-4px) creating a physical "raised" look
- **Corners**: Pixel stair-step via `PixelContainer(notchSize: 3)` — no smooth radius
- **Icon**: Left-aligned play-triangle or relevant icon in dark color
- **Text**: Bold uppercase, dark color on gold fill
- **Min height**: 48px touch target

### Secondary Button (RESTART, FINISH, PAUSE)
- Same construction as primary but with different fill gradients:
  - PAUSE: Magenta-to-purple gradient
  - RESTART: Yellow-to-orange gradient
  - FINISH: Red-to-magenta gradient
- Text and icon in white

### Disabled Button
- Fill desaturated to 40% opacity
- Arrow/icon grayed out
- No 3D depth (flat bottom edge — looks "sunk in")

### Construction Rules for New Buttons
- ALWAYS include 3D depth (darker bottom edge)
- ALWAYS include a dark outer border
- ALWAYS use uppercase text
- Icon on the left, text on the right
- When multiple buttons appear in a row, the primary action is largest; secondary actions are smaller but same height

---

## 7. Badges and HUD Elements

### Status Badge (Connected, Timer)
- **Fill**: Night plum or transparent dark
- **Border**: 2px, electric violet or magenta
- **Corner radius**: 6-8px (slightly rounded rectangle)
- **Content**: Icon + text, horizontally laid out
- **Position**: Top edge of screen, inside safe area

### Heart Rate Display
- **Shape**: Pixel-art heart icon
- **Fill**: Red (#FF3344) with subtle darker shading for 3D
- **Number**: White, centered inside or overlapping the heart
- **Position**: Top-right corner

### Increment Badge (+5 / -5)
- **Fill**: Transparent with gold (#FFD700) border
- **Text**: Gold, small, bold
- **Position**: Directly above the up arrow (+5) and below the down arrow (-5)

### Warning Indicator
- **Shape**: Pixel-art triangle
- **Fill**: Amber (#FFBF00)
- **Position**: Top-center, between timer and HR (only during active workout when degraded)

### Rules for New HUD Elements
- Keep them small and peripheral — the center panel is the star
- Use bordered badges (not floating text)
- Position along the top or bottom edges, never mid-screen competing with the panel
- Use palette colors only

---

## 8. Icons

All icons follow pixel-art construction:

- Built from straight segments and 90-degree pixel steps (no smooth curves or anti-aliasing)
- Monochrome per icon (one fill color + one shadow/highlight color for 3D)
- Standard sizes: 16x16 for badges, 24x24 for buttons, 32x32+ for featured icons
- Icon colors match their context (gold for arrows, cyan for Bluetooth, red for heart, etc.)

### Established Icon Set

| Icon | Color | Context |
|------|-------|---------|
| Up arrow (chunky) | Gold with orange shadow | Directional indicator |
| Down arrow (chunky) | Gold with orange shadow | Directional indicator |
| Heart | Red with dark shading | Heart rate display |
| Play triangle | Dark on gold, or white on color | START, RESUME buttons |
| Pause bars | White or gold | PAUSE button |
| Stop square | White | FINISH button |
| Circular arrow | White | RESTART button |
| Stopwatch/clock | Gold or orange | Timer badge |
| Warning triangle | Amber | Connection degraded |
| Bluetooth | Neon cyan | Scan screen |
| Signal bars | Green/cyan | Device signal strength |
| Green dot | Green (#00FF66) | Connected status |
| Close/X | Warm cream | Dismiss buttons (sheets, dialogs) |

### Rules for New Icons
- MUST follow pixel-art stepped construction
- MUST use only palette colors (or the extended functional colors)
- Include a shadow/depth color for any icon larger than 16x16
- Keep detail minimal — icons should read clearly at small sizes

---

## 9. Motion and Animation

All animations reinforce the arcade game feel. They should feel snappy and
physical — like pressing real buttons and interacting with a game machine.

### 9.1 Button Press / Release

Applies to ALL tappable buttons (START, PAUSE, RESUME, RESTART, FINISH, DONE,
device cards, any future buttons).

| Phase | Property | Value | Duration | Curve |
|-------|----------|-------|----------|-------|
| **onPress** | translateY | +2-3px (down) | 50ms | linear |
| **onPress** | bottom shadow height | shrink to 0-1px | 50ms | linear |
| **onPress** | fill brightness | +10% | 50ms | linear |
| **onRelease** | translateY | back to 0, overshoot -1px | 150ms | elasticOut |
| **onRelease** | bottom shadow height | restore to full | 150ms | elasticOut |
| **onRelease** | fill brightness | restore | 150ms | easeOut |

The button should feel like it physically sinks into the surface on press and
springs back on release.

### 9.2 Arrow Button Tap

In addition to the standard button press/release:

| Phase | Property | Value | Duration |
|-------|----------|-------|----------|
| **onTap** | arrow scale | 100% → 110% → 100% | 120ms |
| **disabled tap** | arrow translateX | 0 → -3px → +3px → 0 (shake) | 200ms |

Pairs with existing haptic feedback (lightImpact on tap, no haptic on disabled shake).

### 9.3 Start Button Throb (Idle Only)

The START button throbs when visible to invite interaction. PAUSE and other
active-state buttons do NOT throb.

| Property | Value | Duration | Curve |
|----------|-------|----------|-------|
| scale | 100% ↔ 105% | 2s cycle | sine (smooth oscillation) |
| fill brightness | normal ↔ +8% | 2s cycle (synced) | sine |
| outer glow opacity | 0% ↔ 30% | 2s cycle (synced) | sine |
| glow color | gold (#FFD700) | — | — |

The throb STOPS immediately when the button is pressed (transition to press state).

### 9.4 Radar Sweep (Scan Screen)

| Element | Animation | Duration | Notes |
|---------|-----------|----------|-------|
| Sweep beam | 360° rotation, continuous | 3s per revolution | Cyan/magenta beam |
| Beam trail | Phosphor fade behind beam | 1s fade to 0% | Trails the beam by ~90° |
| Concentric rings | Slow outward expansion + fade | 4s cycle | Rings expand from center, fade at edge |
| Bluetooth icon glow | Pulse opacity 60% ↔ 100% | 4s cycle (synced with rings) | Neon cyan |
| Device discovery | Flash at radar point, card slides in from bottom | 300ms flash, 400ms slide | Bounce ease on slide |

### 9.5 Background Particle Drift

Applies to ALL screens. Particles are always gently alive.

| Property | Value | Notes |
|----------|-------|-------|
| Drift direction | Downward | All particles drift down |
| Drift speed | 5-10px/sec | Varies by particle size |
| Size parallax | 2x2 blocks drift faster than 1px particles | Creates depth |
| Loop | Particles re-enter at top when exiting bottom | Seamless loop |
| Density variation | Slightly denser at bottom of screen | Matches static design |

Performance: Render with `CustomPainter` inside a `RepaintBoundary`.

### 9.6 Speed Streak Shimmer

Applies to screens that have speed streaks (most screens except scan).

| Property | Value | Duration |
|----------|-------|----------|
| Traveling highlight | A brighter band moves along streak length | 4s cycle |
| Highlight opacity | 0% → 40% → 0% as it passes | — |
| Highlight width | ~15% of streak length | — |

Subtle — should be felt, not consciously noticed.

### 9.7 Background Breathing (Active Workout Only)

| Property | Value | Duration |
|----------|-------|----------|
| Band saturation | ±5% oscillation | 6s cycle |
| Curve | sine | Smooth, imperceptible |

Only during active workout state. Idle, paused, and other screens: static bands.

### 9.8 Resistance Change Reaction

When the resistance number changes (up or down tap):

| Property | Value | Duration |
|----------|-------|----------|
| Background vertical shift | 2-3px in tap direction (up on increase, down on decrease) | 200ms |
| Snap back | Returns to original position | 200ms, easeOut |
| Number text | Quick scale pulse 100% → 108% → 100% | 150ms |

Pairs with existing haptic (lightImpact).

### 9.9 Screen Transitions

| Transition | Animation | Duration |
|------------|-----------|----------|
| Scan → Main | Slide in from right, slight scale-up from 95% | 300ms, easeOut |
| Main → Summary | Slide up from bottom with bounce | 400ms, elasticOut |
| Any → Disconnect/Scan | Fade out + slight scale-down to 95% | 250ms, easeIn |

### 9.10 Heart Rate Pulse

| Property | Value | Duration |
|----------|-------|----------|
| Heart icon scale | 100% → 112% → 100% | Synced to actual HR if available, otherwise 1s cycle |
| Color intensity | Normal → +15% brightness → normal | Synced with scale |

When HR is connected and reading, the heart icon beats in time with the
actual heart rate. When not connected, it pulses at a steady 1-beat-per-second.

---

## 10. Spacing and Layout

### General Rules
- The center panel is the focal point. It occupies roughly 50-60% of screen height, centered vertically.
- HUD elements (badges, timer, HR) live in the top 10% inside the safe area.
- Action buttons live in the bottom 10-15%.
- The background is ALWAYS visible around the center panel — panels never extend edge-to-edge.
- **Modal bottom sheets** also follow this rule: add horizontal padding (16px) so they float with visible margins. Use 4px top corner radius to match panel style.
- Minimum margin from screen edge to panel: 16px.
- Content within panels: 16-24px padding.

### Touch Targets
- Minimum tappable area: 44x44pt (Apple HIG)
- Arrow buttons: full width of the center panel, generous vertical padding (60-80px height)
- Bottom buttons: minimum 48px height, 120px+ width

### Responsive Scaling
- On smaller screens (iPhone SE): reduce panel padding and number font size, maintain button sizes
- On larger screens (iPhone Pro Max): increase panel padding, allow number font to grow
- NEVER let the panel touch the screen edges
- NEVER let buttons overlap the panel

---

## 11. Accessibility

### Contrast
- White text on night plum panel: meets WCAG AAA (ratio > 13:1)
- Gold text on dark buttons: verify minimum AA (ratio > 4.5:1)
- All interactive elements must meet minimum contrast requirements

### Motion Sensitivity
- Respect the system "Reduce Motion" setting:
  - Disable: particle drift, streak shimmer, start button throb, background breathing
  - Keep: button press/release (functional feedback), screen transitions (use cross-fade instead of slides)
  - Reduce: heart rate pulse (static icon instead)

### Screen Reader
- All buttons must have semantic labels
- Resistance level announced on change
- Connection status announced on change
- Heart rate announced periodically (not on every beat)

---

## 12. Checklist for New Screens

When building any new screen, verify:

- [ ] Uses the banded background system with dithering
- [ ] Pixel particles are present and drifting
- [ ] All containers use the standard panel construction (dark fill, colored border, rounded corners)
- [ ] All buttons use the arcade button construction (3D depth, dark border, uppercase text)
- [ ] Button press/release animations are implemented
- [ ] Colors are strictly from the 8-color palette + extended functional colors
- [ ] Icons follow pixel-art stepped construction
- [ ] Text is uppercase for headings/buttons, white on dark surfaces
- [ ] Touch targets meet 44x44pt minimum
- [ ] HUD elements are positioned at screen edges, not competing with center content
- [ ] Reduce Motion is respected
- [ ] Screen transition animation follows the established patterns
- [ ] No Flutter Material widgets used where a pixel-art equivalent exists (see Section 13)
- [ ] No third-party animation/visual packages (build custom painters instead)
- [ ] Buttons inside Wrap/Row/Flex layouts don't stretch beyond intrinsic width

---

## 13. Implementation Pitfalls (Lessons Learned)

These rules were discovered through real bugs where the 8-bit aesthetic was
broken by Flutter defaults or smooth-rendering habits. Follow these to avoid
repeating the same mistakes.

### 13.1 No Material Icons — Use PixelIcon

Flutter's `Icons.close`, `Icons.arrow_back`, etc. are smooth vector icons
that break the pixel-art aesthetic. ALWAYS use `PixelIcon` from the custom
icon set instead. If a needed icon doesn't exist yet, add it to
`pixel_icon.dart` following the pixel-art stepped construction rules.

**Bad:** `Icon(Icons.close, color: AppColors.warmCream)`
**Good:** `PixelIcon.close(size: 24, color: AppColors.warmCream)`

### 13.2 No CircularProgressIndicator — Use Animated Text

Flutter's `CircularProgressIndicator` is a smooth spinning arc. For loading
states, use an animated dot sequence instead (cycling "." → ".." → "...").
This matches the retro terminal/arcade feel.

**Bad:** `CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan)`
**Good:** `Text('SEARCHING$dots', style: ...)` with a periodic timer cycling
1-3 dots

### 13.3 No Third-Party Visual Packages

Packages like `confetti`, `lottie`, `shimmer`, etc. render smooth
animations that clash with the pixel aesthetic. ALWAYS build custom
`CustomPainter` implementations using pixel blocks (small rectangles)
instead. This ensures the visual style stays consistent.

**Bad:** `ConfettiWidget(...)` from a package
**Good:** `PixelCelebrationPainter(...)` drawing falling colored squares

### 13.4 CustomPainters Must Use Pixel Blocks

When writing any `CustomPainter` for visual effects (radar, celebrations,
indicators), render with small rectangles snapped to a grid instead of
smooth primitives:

- Use `canvas.drawRect()` instead of `canvas.drawLine()` or `canvas.drawCircle()`
- Snap coordinates to a grid: `(x / blockSize).round() * blockSize`
- Typical block sizes: 4x4 for large painters, 2x2 for small ones
- Circles become staircase rings (pixel blocks stepped along circular paths)
- Lines become trails of pixel blocks

### 13.5 Buttons Must Not Stretch

When `ArcadeButton` is placed inside a `Wrap`, `Row`, or any flex layout,
the outer `Container` will expand to fill available width, causing the
border and 3D shadow to stretch into visible horizontal lines beyond the
button text. Wrap the button's outer container in `UnconstrainedBox` so it
shrinks to its intrinsic width.

### 13.6 Pixel Stair-Step Corners, Not Rounded

All arcade containers (panels, buttons, badges) use `PixelContainer` with
2-step staircase corners. NEVER use `BorderRadius.circular()` for arcade
containers — it produces smooth curves that break the 8-bit aesthetic.

**Bad:** `BorderRadius.circular(4)` on a `Container`
**Good:** `PixelContainer(notchSize: 4, ...)` or `ArcadePanel(...)`

### 13.7 Bottom Sheets Need Margins

`showModalBottomSheet` containers go edge-to-edge by default. Always wrap
the sheet content in horizontal `Padding(padding: EdgeInsets.symmetric(horizontal: 16))`
so it floats with visible background on both sides. Use 4px top corner
radius to match panel style.

### 13.8 Celebration/Title Text Must Be Prominent

Screen headlines like "WORKOUT COMPLETE!" should be large (20pt+), not the
same size as body labels. When a screen exists to celebrate or announce
something, make that text the dominant visual element. Don't use the same
small font size as regular UI labels.

### 13.9 Button Top Fill Must Stretch to Full Width

`ArcadeButton` uses a `Column` with a top-color `Container` (the button
face) and a bottom-color `Container` (the 3D depth strip). Because
`UnconstrainedBox` removes parent constraints, `minWidth` can force the
outer `PixelContainer` wider than the inner content. If the top-color
`Container` uses `MainAxisSize.min`, it will be narrower than the button
border, leaving the bottom color visible on both sides — making the button
look broken (gold rectangle floating on a darker rectangle).

**Fix:** The `Column` uses `CrossAxisAlignment.stretch` wrapped in
`IntrinsicWidth` to resolve the infinite max-width from `UnconstrainedBox`
into a tight constraint. This ensures the top fill always covers the full
button width.
