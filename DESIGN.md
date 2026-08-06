---
name: Maybe
description: The OS for your personal finances
colors:
  primary-text: "#171717"
  primary-text-inverse: "#ffffff"
  secondary-text: "#737373"
  subdued-text: "#9E9E9E"
  link-text: "#1570EF"
  surface-bg: "#F7F7F7"
  container-bg: "#ffffff"
  surface-inset-bg: "#F0F0F0"
  inverse-bg: "#363636"
  overlay-bg: "#F0F0F080"
  destructive: "#EC2222"
  success: "#10A861"
  warning: "#DC6803"
  border-primary: "#0B0B0B26"
  border-secondary: "#0B0B0B1A"
  border-tertiary: "#0B0B0B0D"
  alpha-black-50: "#0B0B0B08"
  alpha-black-100: "#0B0B0B14"
  alpha-black-200: "#0B0B0B1A"
  alpha-black-300: "#0B0B0B26"
  alpha-white-50: "#FFFFFF08"
  alpha-white-100: "#FFFFFF14"
  alpha-white-200: "#FFFFFF1A"
  alpha-white-300: "#FFFFFF26"
  alpha-white-400: "#FFFFFF33"
  gray-25: "#FAFAFA"
  gray-50: "#F7F7F7"
  gray-100: "#F0F0F0"
  gray-200: "#E7E7E7"
  gray-300: "#CFCFCF"
  gray-400: "#9E9E9E"
  gray-500: "#737373"
  gray-600: "#5C5C5C"
  gray-700: "#363636"
  gray-800: "#242424"
  gray-900: "#171717"
typography:
  display:
    fontFamily: "Geist, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "clamp(1.25rem, 4vw, 1.875rem)"
    fontWeight: 500
    lineHeight: 1.2
  title:
    fontFamily: "Geist, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: 1.5
  body:
    fontFamily: "Geist, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Geist, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 400
    lineHeight: 1.5
  mono:
    fontFamily: "Geist Mono, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.5
rounded:
  sm: "6px"
  md: "8px"
  lg: "10px"
  xl: "12px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
components:
  button-primary:
    backgroundColor: "{inverse-bg}"
    textColor: "{primary-text-inverse}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
    typography: "{title}"
  button-primary-hover:
    backgroundColor: "#242424"
    textColor: "{primary-text-inverse}"
  button-primary-disabled:
    backgroundColor: "#737373"
    textColor: "{primary-text-inverse}"
  button-secondary:
    backgroundColor: "#F7F7F7"
    textColor: "{primary-text}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
  button-secondary-hover:
    backgroundColor: "#F0F0F0"
  button-destructive:
    backgroundColor: "#EC2222"
    textColor: "{primary-text-inverse}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
  button-destructive-hover:
    backgroundColor: "#C91313"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{primary-text}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{primary-text}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
  button-ghost-hover:
    backgroundColor: "#F0F0F0"
  button-icon:
    backgroundColor: "transparent"
    rounded: "{rounded.lg}"
    size: "36px"
  tabs-nav:
    backgroundColor: "{surface-inset-bg}"
    rounded: "{rounded.lg}"
    padding: "4px"
  tab-active:
    backgroundColor: "{container-bg}"
    textColor: "{primary-text}"
    rounded: "{rounded.md}"
  card:
    backgroundColor: "{container-bg}"
    rounded: "{rounded.xl}"
  input:
    backgroundColor: "{container-bg}"
    borderColor: "{border-secondary}"
    rounded: "{rounded.md}"
    textColor: "{primary-text}"
  input-focus:
    borderColor: "{border-secondary}"
  toggle-track:
    backgroundColor: "#F0F0F0"
    rounded: "{rounded.full}"
    size: "36px 20px"
  toggle-thumb:
    backgroundColor: "{primary-text-inverse}"
    rounded: "{rounded.full}"
    size: "16px"
  toggle-checked:
    backgroundColor: "#10A861"
  dialog:
    backgroundColor: "{container-bg}"
    rounded: "{rounded.xl}"
  alert-info:
    backgroundColor: "#EFF8FF"
    textColor: "#175CD3"
    borderColor: "#D1E9FF"
    rounded: "{rounded.lg}"
  alert-success:
    backgroundColor: "#ECFDF3"
    textColor: "#078C52"
    borderColor: "#D1FADF"
    rounded: "{rounded.lg}"
  alert-warning:
    backgroundColor: "#FFFAEB"
    textColor: "#B54708"
    borderColor: "#FEF0C7"
    rounded: "{rounded.lg}"
  alert-destructive:
    backgroundColor: "#FFF1F0"
    textColor: "#C91313"
    borderColor: "#FFDEDB"
    rounded: "{rounded.lg}"
  nav-item:
    rounded: "{rounded.md}"
---

# Design System: Maybe

## Overview

**Creative North Star: "The Financial Cockpit"**

Maybe is a measured and professional financial operating system. Like a pilot's instrument panel, every pixel has a job — the interface is a calm, trustworthy environment where complex financial data is organized with precision and clarity. The warm-leaning neutral palette brings a human touch to what could otherwise be cold numbers, making the precision feel approachable rather than clinical.

The system is intentionally restrained. The monochrome gray foundation is the discipline: color appears only when the numbers demand attention — red for losses, green for gains, yellow for warnings. This makes every color event meaningful and impossible to miss. Tonal layering (surface → container → inset) creates depth without shadows, keeping the interface flat, clean, and scannable.

Density balances information richness with breathing room. Charts and data visualizations are the primary visual element, not decorative UI. The design recedes so the data leads.

**Key Characteristics:**
- Warm-leaning neutral palette with precise tonal layering
- Color is reserved for semantic meaning only
- Flat surfaces with structural 1px alpha borders
- Geist typeface for a modern, legible, slightly warm sans-serif voice
- Rounded corners (8–12px) soften the precision without sacrificing professionalism
- Dark mode is a first-class citizen with fully inverted tonal roles

## Colors

The palette is built on a warm-leaning gray scale with semantic accent colors. The grays are not strictly neutral — they carry a subtle warmth (avoiding blue/gray coldness) that makes the interface feel more natural and less corporate.

### Neutral
- **Warm Black** (#171717): Primary text, dark mode container backgrounds. The darkest tone — high contrast without being a pure #000.
- **Primary Text** (#171717): Body and heading text in light mode. Measured black, not absolute.
- **Inverse Text** (#FFFFFF): Text on dark surfaces, light mode container backgrounds.
- **Secondary Text** (#737373, gray-500): Supporting text, metadata, secondary labels. Readable but unobtrusive.
- **Subdued Text** (#9E9E9E, gray-400): Placeholders, disabled text, hints. The quietest readable tone.
- **Surface** (#F7F7F7, gray-50): Page-level background. The lightest tonal layer.
- **Container** (#FFFFFF, white): Card, dialog, and elevated surface backgrounds. The content layer.
- **Surface Inset** (#F0F0F0, gray-100): Nested surfaces, tab bar backgrounds, pressed states. One step deeper.
- **Inverse** (#363636, gray-700): Primary button backgrounds in light mode. A dark but not black surface.
- **Gray-25** (#FAFAFA): The lightest perceptible tone. Used for subtle tinting.
- **Gray-200** (#E7E7E7): Hover states on inset surfaces, subtle dividers.
- **Gray-300** (#CFCFCF): Disabled borders, low-priority dividers.
- **Gray-600** (#5C5C5C): Secondary text alternative in dark mode contexts.
- **Gray-800** (#242424): Hover states on dark surfaces, inset dark backgrounds.

### Semantic
- **Destructive** (#EC2222 / #F13636): Errors, destructive actions, negative amounts. Red-600 in light, Red-400 in dark mode.
- **Success** (#10A861 / #12B76A): Positive amounts, completed states, confirmations. Green-600 in light, Green-500 in dark.
- **Warning** (#DC6803 / #F79009): Alerts, cautionary states, pending items. Yellow-600 in light, Yellow-500 in dark.
- **Link** (#1570EF / #2E90FA): Interactive text links. Blue-600 in light, Blue-500 in dark.

### Alpha Borders
- **Border Primary** (6% black / 26% white in dark): Card borders, container outlines. The structural boundary.
- **Border Secondary** (10% black / 20% white in dark): Input borders, secondary dividers. Slightly stronger.
- **Border Tertiary** (5% black / 15% white in dark): Subtle dividers, menu separators. The quietest line.
- **Border Subdued** (3% black / 8% white in dark): The faintest structural line. Almost invisible but present.

### Named Rules
**The One-Voice Rule.** The gray palette speaks in one voice across the entire interface. Semantic color (red, green, yellow, blue) is the only exception — and it is used on no more than 10% of any given screen. Color rarity is the point: when it appears, the user knows it means something.

**The Warm-Not-Cold Rule.** Gray tones lean warm, never blue-gray. This prevents the interface from feeling clinical or corporate. The warmth is subtle — barely perceptible in isolation — but unmistakable in aggregate.

## Typography

**Display Font:** Geist (with system-ui, -apple-system, BlinkMacSystemFont fallback)
**Mono Font:** Geist Mono (with ui-monospace, SFMono-Regular, Menlo fallback)

**Character:** Geist is a modern, geometric sans-serif with a subtle warmth that matches the palette's character. It is legible at small sizes, distinctive at display sizes, and neutral enough to never compete with the data. The pairing with Geist Mono creates a natural technical-voice for financial figures, codes, and identifiers.

### Hierarchy
- **Display** (Medium 500, clamp(1.25rem, 4vw, 1.875rem), 1.2): Dashboard welcome messages, page titles. Appears at the top of primary surfaces. Sets the tone for the page.
- **Title** (Medium 500, 1rem/14px, 1.5): Button labels, card titles, navigation items, table headers. The most common "heading" in the system — compact but distinct.
- **Body** (Regular 400, 0.875rem/14px, 1.5): Primary reading text, transaction descriptions, paragraphs, table cells. The system's default size.
- **Label** (Regular 400, 0.75rem/12px, 1.5): Form labels, field descriptions, metadata, timestamps, secondary information. The smallest readable size.
- **Mono** (Regular 400, 0.875rem/14px, 1.5): Financial figures, code snippets, identifiers, transaction IDs. Only used where monospace adds clarity.

### Named Rules
**The Single-Size Rule.** The system uses a compact type scale — display, title, body, and label. No headline, no massive hero text. The app is an operating tool, not a marketing page; typographic hierarchy is about scanability, not drama.

## Layout

The layout is a three-panel desktop structure with a unified mobile single-column:
- **Desktop**: 84px icon nav (left) → collapsible sidebar (max 320px) → main content (max-w-5xl, centered) → collapsible AI chat sidebar (max 400px)
- **Mobile**: Top nav bar with hamburger → full-width content → bottom tab bar

The primary content area is capped at `max-width: 1024px` (5xl) and horizontally centered. Sidebars collapse on user preference, toggled via the panel-left/panel-right icons.

Spacing follows a consistent 4px grid: xs (4px), sm (8px), md (12px), lg (16px), xl (24px). Component padding uses the sm-lg range (8-16px). Page sections are separated by `space-y-6` (24px) within the dashboard.

Forms use a compact density: form fields are `px-3 py-2` (12px horizontal, 8px vertical) with `gap-1` (4px) between label and input.

## Elevation & Depth

The system is flat with tonal layering. Surfaces create depth through background color shifts, not shadows. The layer hierarchy is:

1. **Surface** (gray-50 / black) — the page-level background
2. **Container** (white / gray-900) — cards, dialogs, elevated content
3. **Surface Inset** (gray-100 / gray-800) — nested surfaces, tab bar backgrounds

The 1px alpha border (`shadow-border-xs` through `shadow-border-xl`) is a **structural line**, not an atmospheric shadow. It defines the boundary of a container against its background. The accompanying shadow (`--shadow-*`) is deliberately subtle — it exists only to prevent the 1px border from feeling like a hard cut.

### Shadow Vocabulary
- **shadow-xs** (0px 1px 2px, 6%): Default container boundary. The structural minimum.
- **shadow-sm** (0px 1px 6px, 6%): Slightly lifted containers. Hovered cards.
- **shadow-md** (0px 4px 8px -2px, 6%): Dropdown menus, popovers, dialogs.
- **shadow-lg** (0px 12px 16px -4px, 6%): Large modals, full-screen drawers.
- **shadow-xl** (0px 20px 24px -4px, 6%): Maximum elevation. Reserved for the most prominent overlays.

### Named Rules
**The Flat-By-Default Rule.** Surfaces are flat at rest. Shadows appear only as a structural affordance (containers against their background) or as a response to state (hover, focus). No decorative shadows.

## Shapes

Corners are rounded with a consistent 8-12px vocabulary that scales with element size:
- **Small radius** (6px, rounded-md): Tab items, small buttons, checkboxes
- **Medium radius** (8px, rounded-lg): Primary/secondary buttons, form fields, alerts, dialog containers, tab bar containers
- **Large radius** (12px, rounded-xl): Large buttons, cards, dialogs
- **Full radius** (9999px, rounded-full): Toggle switches, avatar circles, pill badges

The corner strategy is uniform — all square components use the same radius within their size tier. The rounding is intentional: it softens the precision of financial data without undermining its authority. 8px is the default radius for most interactive elements; 12px is reserved for the largest containers.

Borders are 1px wide, always using alpha values (not solid colors) to maintain hierarchy without introducing additional hues. The alpha values shift in dark mode to maintain the same perceived contrast.

## Components

### Buttons
- **Shape:** Rounded corners scale with size — sm (6px, rounded-md), md (8px, rounded-lg), lg (12px, rounded-xl). The default size is md (8px radius).
- **Primary:** Dark background (gray-700/gray-900), white text, full-width padding (12px 16px). Hover shifts to one tone darker (gray-800), disabled sinks to gray-500.
- **Secondary:** Light background (gray-50), dark text, same padding. Hover shifts to gray-100. Dark mode reverses: gray-700 background, white text.
- **Destructive:** Red background (red-500/red-400), white text. Hover intensifies the red. Used only for destructive actions — its rarity makes it impactful.
- **Outline:** Transparent background with a 1px alpha border (border-secondary). Hover adds a surface-hover background. Used for secondary actions in dense contexts.
- **Ghost:** No background or border at rest. Hover adds a subtle background (gray-100). Used in toolbars, menus, and inline action areas.
- **Icon:** Square (36px for md, 32px for sm, 40px for lg), no text, icon-only. Hover follows ghost behavior. Used for utility actions.
- **Icon Inverse:** Dark background with light icon. Used on dark surfaces.
- **Hover / Focus:** All buttons have a `focus-visible:outline-gray-900` focus ring. Hover states use a 200ms transition. Interactive buttons are `cursor-pointer`.
- **Font:** All buttons use `font-medium` (500 weight) with `whitespace-nowrap` to prevent text wrapping.

### Tabs (Segmented Control)
- **Shape:** Pill-style segmented control in a rounded container (4px padding, 8px radius).
- **Container:** Surface-inset background (gray-100 / gray-800), rounded-lg (8px).
- **Default:** Inactive tabs use secondary text color with hover background on the inset surface.
- **Active:** The active tab lifts onto a white/gray-700 container with a subtle shadow-sm. This is the one place where shadow is used as a selection indicator.
- **Transition:** 200ms color transition on hover.

### Cards / Containers
- **Corner Style:** Large radius (12px, rounded-xl).
- **Background:** Container background (white/gray-900).
- **Boundary:** 1px alpha border (shadow-border-xs) — a structural line, not a shadow.
- **Internal Padding:** 16px (p-4) standard, with 24px (py-4) for chart containers that need vertical breathing room.
- **Cards do not** have separate hover states. They are containers, not interactive elements.

### Inputs / Fields
- **Style:** 1px alpha border (border-secondary), container background, 8px radius (rounded-lg). Internal padding: 12px horizontal, 8px vertical.
- **Focus:** The border stays at secondary strength but the container gains a 4px alpha ring (`focus-within:ring-4`, `ring-alpha-black-200`). The transition is 300ms.
- **Placeholder:** Subdued text color (gray-400/gray-600) at 50% opacity.
- **Disabled:** Subdued text color, reduced opacity.
- **Error:** No dedicated error border style observed — errors are surfaced via the Alert component or inline validation messages.

### Toggle
- **Shape:** Rounded pill (36px wide, 20px tall). The thumb is a 16px white circle.
- **Default:** Light gray track (gray-100/gray-700), 300ms color transition.
- **Checked:** Green track (green-600/green-500). Thumb slides 16px right with a 300ms ease-in-out transform.
- **Disabled:** 70% opacity, `cursor-not-allowed`.

### Alerts
- **Shape:** 8px radius (rounded-lg), 1px colored border, 16px padding, flex layout with icon + message.
- **Variants:** Four semantic variants — info (blue), success (green), warning (yellow), destructive (red). Each variant uses a tinted background, matching border, and darker text from the same hue family.
- **Icons:** Each variant has a dedicated icon (info, check-circle, alert-triangle, x-circle) in the matching semantic color. Icons are always 16px.

### Dialogs
- **Shape:** Large radius (12px, rounded-xl), container background, shadow-border-xs structural boundary.
- **Variants:** Modal (centered, max-h-full) and Drawer (right-aligned, full height, 550px wide).
- **Widths:** sm (300px), md (550px), lg (700px), full (100%).
- **Header:** 16px padding, flex layout with title + optional close button. Title uses `font-medium` (500) with `text-primary`.
- **Actions:** Bottom area renders a row of `DS::Button` components. Cancel actions close the dialog.

### Tooltips
- **Behavior:** Floating element positioned via the Floating UI library. Controlled by a Stimulus controller.
- **Placement:** Configurable (top, bottom, left, right, with various alignment options).
- **Trigger:** Hover or focus on the target element. Default offset is 10px with zero cross-axis offset.
- **Icon:** Defaults to an info icon (16px) as the trigger target.

### Menus
- **Shape:** Dropdown container with optional header (border-bottom divider), menu items, and custom content.
- **Variants:** Icon trigger, button trigger, avatar trigger. Placement defaults to bottom-end.
- **Items:** Each `DS::MenuItem` is a clickable row. Menu is controlled by a Stimulus controller.

### Navigation
- **Desktop:** 84px-wide fixed icon column on the left. Logomark at top, nav items in the middle, user menu + help icon at the bottom. Active state is indicated by icon color.
- **Mobile:** Bottom tab bar with 4 items (Home, Transactions, Budgets, Assistant). The Assistant tab is mobile-only. A top bar shows the hamburger menu, logomark, and user menu.
- **Sidebar:** Left sidebar contains account navigation tabs. Right sidebar contains the AI chat interface. Both are collapsible via `panel-left` / `panel-right` toggle icons.

## Do's and Don'ts

### Do:
- **Do** use the gray palette as the primary voice of the interface. Color is for semantic meaning only.
- **Do** use tonal layering (surface → container → inset) to create hierarchy. Prefer background shifts over borders or shadows.
- **Do** use the 1px alpha border as a structural line on all elevated containers. It defines the boundary without adding a new color.
- **Do** keep button labels in `font-medium` with `whitespace-nowrap`. Avoid wrapping text in buttons.
- **Do** use the largest corner radius that fits the element — 12px for cards, 8px for buttons, 6px for small controls.
- **Do** maintain the warm-leaning character of the gray tones. Avoid blue-gray or cool-gray substitutions.
- **Do** use semantic color consistently: red for negative, green for positive, yellow for warnings, blue for links/info.

### Don't:
- **Don't** use color decoratively. Every color application must carry meaning.
- **Don't** add shadows to surfaces at rest. The structural 1px border is sufficient.
- **Don't** use pure black (#000) for text or surfaces. The palette's warm black (#171717) is the darkest tone.
- **Don't** introduce additional typefaces beyond the Geist family. The system uses Geist and Geist Mono exclusively.
- **Don't** use filled/heavy button styles for secondary actions. Reserve primary fills for the most important action per surface.
- **Don't** mix corner radius languages. All rounded corners within the same size tier should use the same radius.
- **Don't** create decorative illustrations or iconography that competes with data. The data is the visual.