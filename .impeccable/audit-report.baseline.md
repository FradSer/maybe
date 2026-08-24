# Maybe UI Technical Audit

## Audit Health Score

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 1 | Accessibility | 1/4 | Core icon controls have no accessible names; upload, filters, tooltips, charts, and drawer keyboard behavior have significant gaps. |
| 2 | Performance | 2/4 | D3 charts redraw on every resize and all controllers are eagerly loaded; most surfaces otherwise use restrained effects. |
| 3 | Responsive Design | 1/4 | The application shell enforces `min-w-[480px]` on the main content, and one bulk-selection bar is fixed at 420px with no mobile override. |
| 4 | Theming | 1/4 | A token system exists, but raw color utilities and inline colors remain widespread and several error/import surfaces have no dark-mode variants. |
| 5 | Implementation Integrity | 2/4 | The product has clear finance-specific structure and a recognizable system, but implementation drift is repeated across core and supporting surfaces. |
| **Total** | | **7/20** | **Poor — major overhaul required** |

## Implementation Integrity Verdict

**FAIL.** Maybe still expresses a coherent, product-specific financial cockpit in its information architecture: account groups, budgets, transactions, net worth, cashflow, and AI chat are all explicit domain surfaces. The shared design-system components and semantic tokens are also real and used in many core paths.

However, the implementation does not consistently preserve that system. A sweep of the current tree found roughly 45 hard-coded color utility occurrences in views/components outside token definitions, including raw blue/red/yellow surfaces without dark variants (`app/views/imports/new.html.erb:32`, `app/views/pages/redis_configuration_error.html.erb:8-20`, `app/views/plaid_items/_plaid_item.html.erb:9-14`). Core layout controls also omit names, responsive sizing is contradicted by a global 480px minimum, and the password page renders an empty heading because `t` is evaluated without output (`app/views/passwords/edit.html.erb:1`). These are deterministic implementation issues, not visual taste judgments. The result is a recognizable product shell with systemic drift rather than a fully coherent, intentional design-system implementation.

## Executive Summary

- Audit Health Score: **7/20** (**Poor — major overhaul required**)
- Total issues found: **0 P0 / 9 P1 / 9 P2 / 0 P3**
- Top issues:
  1. Icon-only navigation and utility controls are emitted without accessible names, including mobile navigation, sidebar toggles, help, and dismiss controls (`app/helpers/application_helper.rb:32-53`, `app/views/layouts/application.html.erb:51-65`, `app/views/layouts/application.html.erb:99-104`, `app/views/layouts/application.html.erb:156-164`).
  2. The app shell requires 480px minimum main-content width at every breakpoint, creating horizontal overflow on narrow mobile devices (`app/views/layouts/application.html.erb:153`).
  3. Theme drift is systemic: raw colors in core surfaces bypass tokens, and the Redis configuration error surface has no dark-mode treatment (`app/views/pages/redis_configuration_error.html.erb:8-20`, `app/views/imports/new.html.erb:32-39`).
  4. The CSV upload drop zone presents a `role="button"` but only responds to click; Enter/Space keyboard activation is not wired (`app/views/import/uploads/show.html.erb:28-44`, `app/javascript/controllers/file_upload_controller.js:28-32`).
  5. Financial charts expose only generic `role="img"` labels and no equivalent data table or textual values (`app/views/pages/dashboard/_net_worth_chart.html.erb:39-46`, `app/views/pages/dashboard/_cashflow_sankey.html.erb:26-34`).
- Recommended next steps: harden core keyboard/name semantics first, remove mobile minimum-width constraints, consolidate view colors onto semantic tokens with explicit dark variants, then optimize chart/controller lifecycle and run a follow-up audit.

## Detailed Findings by Severity

### P1 — Major

#### [P1] Icon-only controls are unnamed across the application shell

- **Location:** `app/helpers/application_helper.rb:32-53`; `app/views/layouts/application.html.erb:51-65`, `app/views/layouts/application.html.erb:99-104`, `app/views/layouts/application.html.erb:156-164`.
- **Category:** Accessibility
- **Impact:** `icon(..., as_button: true)` renders a button but does not derive an accessible label. The mobile drawer close button, mobile hamburger, desktop sidebar toggles, and Intercom/help control therefore expose only an SVG to assistive technology. Keyboard and screen-reader users cannot reliably discover or operate major navigation controls.
- **WCAG/Standard:** WCAG 4.1.2 Name, Role, Value; WCAG 2.4.6 Headings and Labels.
- **Recommendation:** Require an explicit `aria-label`/visible text for every icon-only button, and make the helper fail loudly or provide a label argument when used as a button. Add state labels to sidebar toggles (for example, “Show account sidebar”/“Hide account sidebar”).
- **Suggested command:** `$impeccable harden`

#### [P1] Mobile account drawer is not a keyboard-contained dialog

- **Location:** `app/views/layouts/application.html.erb:44-61`; `app/javascript/controllers/app_layout_controller.js:81-99`.
- **Category:** Accessibility / Responsive Design
- **Impact:** The drawer is an `aside` moved off-screen with CSS and marked `aria-hidden`, but it is not inert and has no focus trap. Its links can remain in the document tab order while closed, and focus can escape while it is open. The hamburger also has no `aria-expanded`/`aria-controls` state. This creates invisible focus targets and an unreliable mobile navigation path.
- **WCAG/Standard:** WCAG 2.4.3 Focus Order; WCAG 2.4.7 Focus Visible; WCAG 4.1.2 Name, Role, Value.
- **Recommendation:** Use a dialog/drawer pattern with `inert` on the background, trap focus while open, return focus on close, wire Escape, and synchronize `aria-expanded` and `aria-controls` on the trigger. Do not rely on `aria-hidden` alone for a transformed, still-rendered subtree.
- **Suggested command:** `$impeccable harden`

#### [P1] CSV upload drop zone is not keyboard actionable

- **Location:** `app/views/import/uploads/show.html.erb:28-46`; `app/javascript/controllers/file_upload_controller.js:28-32`.
- **Category:** Accessibility
- **Impact:** The upload target claims `role="button"` and has `tabindex="0"`, but its controller registers only a click action. Enter and Space do not open the file picker, so keyboard-only users cannot upload a CSV through the primary import flow.
- **WCAG/Standard:** WCAG 2.1.1 Keyboard; WCAG 4.1.2 Name, Role, Value.
- **Recommendation:** Prefer a styled `<label>` for the file input. If the custom button remains, handle `keydown` for Enter/Space, prevent default scrolling, and expose selected/uploading state with a live region.
- **Suggested command:** `$impeccable harden`

#### [P1] Transaction filter search fields have no programmatic labels

- **Location:** `app/views/transactions/searches/filters/_merchant_filter.html.erb:3-5`; same pattern in `_account_filter.html.erb:3-5`, `_category_filter.html.erb:3-5`, and `_tag_filter.html.erb:3-5`.
- **Category:** Accessibility
- **Impact:** These search inputs rely on placeholder text (“Filter merchants”, etc.) as their only visible naming. Placeholder text disappears while typing and is not a durable accessible label, making filter context unclear for screen-reader and cognitive users.
- **WCAG/Standard:** WCAG 1.3.1 Info and Relationships; WCAG 3.3.2 Labels or Instructions; WCAG 4.1.2 Name, Role, Value.
- **Recommendation:** Add a visually hidden `<label>` associated with each input (or configure the form builder), preserve the placeholder as a hint, and announce the filtered-result count where useful.
- **Suggested command:** `$impeccable harden`

#### [P1] Financial charts have no equivalent textual data

- **Location:** `app/views/pages/dashboard/_net_worth_chart.html.erb:39-46`; `app/views/pages/dashboard/_cashflow_sankey.html.erb:26-34`.
- **Category:** Accessibility / Implementation Integrity
- **Impact:** The charts are exposed as generic images with labels (“Net worth chart”, “Cashflow sankey chart”), but the underlying financial values, dates, nodes, and links are available only through SVG/hover interactions. Users who cannot perceive or hover the visualization cannot inspect the same financial information.
- **WCAG/Standard:** WCAG 1.1.1 Non-text Content; WCAG 1.3.1 Info and Relationships; WCAG 1.4.13 Content on Hover or Focus.
- **Recommendation:** Provide a compact accessible data table or summary adjacent to each chart, include meaningful chart titles and descriptions, and make data-point details available on keyboard focus rather than hover only.
- **Suggested command:** `$impeccable harden`

#### [P1] Main content has a global 480px minimum width on mobile

- **Location:** `app/views/layouts/application.html.erb:152-153`.
- **Category:** Responsive Design
- **Impact:** `min-w-[480px]` applies without a breakpoint modifier while the layout switches to a single-column mobile shell. On common 320–430px viewports this forces horizontal overflow for every page, undermining the committed mobile layout and making forms/tables require sideways scrolling even when their content could wrap.
- **Recommendation:** Remove the unconditional minimum, use `min-w-0` on the flex child, and apply any desktop content minimum only at the breakpoint where the sidebars are present. Validate at 320, 375, 414, and 430px with increased text size.
- **Suggested command:** `$impeccable adapt`

#### [P1] Entry selection bar overflows narrow screens

- **Location:** `app/views/entries/_selection_bar.html.erb:1-13`.
- **Category:** Responsive Design / Accessibility
- **Impact:** This selection bar is fixed at `w-[420px]` with no mobile override. It will exceed a 320–414px viewport once horizontal padding is included, and the delete button is only `p-1.5` (about 30px) with a title but no `aria-label`. Bulk actions can be clipped and the destructive action is difficult to target.
- **Recommendation:** Match the responsive `w-[90%] md:w-[420px]` strategy used by the transactions variant, include safe-area/bottom spacing, and give the delete button a 44px target plus an accessible name.
- **Suggested command:** `$impeccable adapt`

#### [P1] Error surface bypasses theme tokens and has no dark-mode branch

- **Location:** `app/views/pages/redis_configuration_error.html.erb:5-20`.
- **Category:** Theming
- **Impact:** The self-hosted Redis configuration failure page uses `bg-red-100`, `text-red-600`, `bg-amber-50`, `border-amber-200`, and `text-amber-800` directly, with no `theme-dark:` alternatives. In dark mode these light tinted surfaces and fixed dark text can produce poor contrast and visibly diverge from the tokenized alert system.
- **Recommendation:** Replace raw utilities with the DS alert/semantic tokens (or add explicit paired dark variants), use the existing alert component, and verify destructive/warning contrast in both themes.
- **Suggested command:** `$impeccable colorize`

#### [P1] Password page renders an empty heading

- **Location:** `app/views/passwords/edit.html.erb:1`.
- **Category:** Accessibility / Implementation Integrity
- **Impact:** `<h1><% t(".title") %></h1>` evaluates the translation without output, leaving an empty heading in the password-change flow. This removes the page’s primary visible context and leaves a misleading heading landmark for assistive technology.
- **WCAG/Standard:** WCAG 1.3.1 Info and Relationships; WCAG 2.4.6 Headings and Labels.
- **Recommendation:** Output the translation and apply the page’s normal heading/token classes. Add a view regression check that asserts the title text is present.
- **Suggested command:** `$impeccable clarify`

### P2 — Minor

#### [P2] Icon-only copy and edit actions fall below the 44px target and lack names

- **Location:** `app/views/mfa/new.html.erb:23-37`; `app/views/settings/profiles/show.html.erb:81-96`; `app/views/accounts/_account.html.erb:26-29`; `app/views/entries/_selection_bar.html.erb:8-12`.
- **Category:** Accessibility / Responsive Design
- **Impact:** Several copy/edit/delete buttons use only text/icon styling without `min-w/min-h-[44px]`; the MFA/profile copy buttons have no `type` or `aria-label`, while the account pencil is an unnamed icon link. Small targets increase missed taps and make controls ambiguous when icons are hidden or not announced.
- **Recommendation:** Standardize these actions on the DS icon/button component, require accessible names, and enforce the project’s 44px minimum target size.
- **Suggested command:** `$impeccable harden`

#### [P2] Focus indicators are explicitly hidden on disclosure summaries

- **Location:** `app/views/plaid_items/_plaid_item.html.erb:5`; `app/views/accounts/index/_manual_accounts.html.erb:3-4`; `app/components/DS/disclosure.html.erb:1-20`.
- **Category:** Accessibility
- **Impact:** `focus-visible:outline-hidden` is applied to native `<summary>` controls while the global stylesheet only provides focus styling for buttons and form fields. Keyboard users can expand/collapse these primary account sections without a visible focus indicator.
- **WCAG/Standard:** WCAG 2.4.7 Focus Visible; WCAG 2.4.11 Focus Not Obscured.
- **Recommendation:** Remove `outline-hidden` and apply a consistent focus-visible ring/outline to the summary itself. Keep the native details/summary semantics.
- **Suggested command:** `$impeccable harden`

#### [P2] Tooltips respond to mouse hover but not keyboard focus

- **Location:** `app/javascript/controllers/tooltip_controller.js:29-32`; `app/components/DS/tooltip.html.erb:1-8`; repeated tooltip markup in `app/views/pages/dashboard/_balance_sheet.html.erb:43-52` and `app/views/pages/dashboard/_cashflow_sankey.html.erb:4-12`.
- **Category:** Accessibility
- **Impact:** The generic controller listens only for `mouseenter`/`mouseleave`; keyboard focus and touch users cannot reveal explanatory financial context. Several triggers are bare icons without a focusable button or descriptive label.
- **WCAG/Standard:** WCAG 1.4.13 Content on Hover or Focus; WCAG 2.1.1 Keyboard.
- **Recommendation:** Use a focusable button trigger, handle `focusin`/`focusout` and Escape, and connect the trigger to the tooltip with `aria-describedby`. Keep the tooltip dismissible and non-obscuring.
- **Suggested command:** `$impeccable harden`

#### [P2] Reduced-motion rule removes all useful transition feedback

- **Location:** `app/assets/tailwind/maybe-design-system.css:448-454`.
- **Category:** Accessibility / Performance
- **Impact:** A global `0.01ms !important` override collapses every animation and transition, including sidebar/drawer state changes and status feedback. Reduced motion should remove vestibular motion, not erase state communication or make controls appear to jump unpredictably.
- **Recommendation:** Replace the blanket kill with component-level reduced-motion alternatives: preserve opacity/state changes, disable only transforms/parallax/spinners where necessary, and retain immediate but perceivable feedback.
- **Suggested command:** `$impeccable animate`

#### [P2] D3 charts fully tear down and redraw on every resize

- **Location:** `app/javascript/controllers/time_series_chart_controller.js:22-37`, `app/javascript/controllers/time_series_chart_controller.js:564-569`; `app/javascript/controllers/sankey_chart_controller.js:14-39`.
- **Category:** Performance
- **Impact:** Each ResizeObserver callback removes the entire SVG and reconstructs scales, paths, gradients, labels, and tooltips. Resizing a window or flex sidebar can trigger repeated expensive redraws and unnecessary DOM churn, especially with large transaction histories or multiple charts on the dashboard.
- **Recommendation:** Coalesce resize notifications with `requestAnimationFrame`, redraw only when dimensions materially change, and update existing SVG geometry where practical. Disconnect observers while a Turbo frame is hidden.
- **Suggested command:** `$impeccable optimize`

#### [P2] Hidden DS tooltips keep Floating UI auto-updates running

- **Location:** `app/components/DS/tooltip.html.erb:1-4`; `app/components/DS/tooltip_controller.js:18-26`, `app/components/DS/tooltip_controller.js:50-58`.
- **Category:** Performance
- **Impact:** The DS tooltip controller calls `startAutoUpdate()` during `connect()` even though the tooltip starts hidden, and does not stop until disconnect. Every hidden tooltip therefore retains a positioning observer/listeners across the page lifecycle.
- **Recommendation:** Start `autoUpdate` only when showing and stop it on hide, matching the existing generic tooltip controller’s lifecycle.
- **Suggested command:** `$impeccable optimize`

#### [P2] File-upload listeners leak on Turbo lifecycle changes

- **Location:** `app/javascript/controllers/file_upload_controller.js:7-15`, `app/javascript/controllers/file_upload_controller.js:18-24`.
- **Category:** Performance
- **Impact:** `addEventListener` receives a fresh `bind(this)` function and `removeEventListener` receives a different fresh bound function. The old listeners are not removed when Turbo replaces the frame, allowing duplicate handlers and retained controller references over repeated visits.
- **Recommendation:** Store bound handler references on connect (or use class-field arrow handlers) and remove those exact references in disconnect.
- **Suggested command:** `$impeccable optimize`

#### [P2] All Stimulus controllers are eagerly loaded, including heavy chart dependencies

- **Location:** `app/javascript/controllers/index.js:3-11`; D3 imports in `app/javascript/controllers/time_series_chart_controller.js:1-2`, `app/javascript/controllers/donut_chart_controller.js:1-2`, and `app/javascript/controllers/sankey_chart_controller.js:1-3`.
- **Category:** Performance
- **Impact:** `eagerLoadControllersFrom("controllers", application)` loads the entire controller set on every page, including D3 and Sankey chart code needed only on selected dashboard/budget surfaces. This increases initial JavaScript work for auth, settings, import, and other pages.
- **Recommendation:** Lazy-load infrequent/heavy controllers or split chart code behind the elements that need it; keep lightweight global controllers eager only where required.
- **Suggested command:** `$impeccable optimize`

#### [P2] User-facing imagery commonly lacks alternative text

- **Location:** `app/views/accounts/_logo.html.erb:10-14`; `app/views/transactions/_transaction.html.erb:22-25`; `app/views/family_merchants/_family_merchant.html.erb:5-8`; `app/views/securities/_combobox_security.turbo_stream.erb:1-3`.
- **Category:** Accessibility / Performance
- **Impact:** Institution, merchant, and security logos are emitted without `alt`, causing screen readers to encounter unlabeled image content (or potentially announce URL-derived names). The images are also remote in several paths, so missing failure behavior can leave ambiguous blank content.
- **Recommendation:** Mark purely decorative logos `alt=""`; provide concise descriptive alt text when an image conveys institution/security identity, and retain lazy loading for below-the-fold lists.
- **Suggested command:** `$impeccable harden`

#### [P2] Core and supporting views bypass semantic color tokens

- **Location:** Representative current occurrences: `app/views/imports/new.html.erb:32-39`, `app/views/plaid_items/_plaid_item.html.erb:9-14`, `app/views/chats/_error.html.erb:3-6`, `app/views/import/confirms/_mappings.html.erb:11-27`, `app/views/subscriptions/upgrade.html.erb:33-36`.
- **Category:** Theming / Implementation Integrity
- **Impact:** Raw `bg-blue-*`, `bg-red-*`, `bg-yellow-*`, text utilities, inline colors, and a decorative gold gradient bypass the committed semantic gray/semantic palette. Several have no dark-mode pair, and the gradient introduces decorative color contrary to the One-Voice Rule. This makes theme behavior and product identity inconsistent across import, chat, error, and billing surfaces.
- **Recommendation:** Route status colors through DS alert variants and semantic tokens, use `theme-dark:` pairs where a raw scale is unavoidable, and remove the decorative gradient in favor of the established neutral/semantic hierarchy. Dynamic user-selected category colors are a valid exception and should remain data-driven.
- **Suggested command:** `$impeccable colorize`

#### [P2] Dialog close affordance is removed from keyboard order

- **Location:** `app/components/DS/dialog.rb:2-7`.
- **Category:** Accessibility
- **Impact:** The shared dialog header renders its close button with `tabindex: "-1"`. Dialogs can be closed with the Escape hotkey, but users navigating by Tab cannot reach the visible close affordance, and the component has no guarantee that every dialog has an alternate close action.
- **WCAG/Standard:** WCAG 2.1.1 Keyboard; WCAG 2.4.3 Focus Order.
- **Recommendation:** Keep the close button in normal tab order, give it an accessible name, and preserve focus restoration after close. Use Escape as an additional mechanism, not the only keyboard path.
- **Suggested command:** `$impeccable harden`

## Patterns and Systemic Issues

- **Accessible naming is not enforced at component boundaries.** `icon(..., as_button: true)` accepts no required label, while ad-hoc icon buttons and copy links repeat the same unnamed-control pattern. The DS menu is a positive counterexample: it now emits `aria-label`, `aria-expanded`, and `aria-haspopup` in `app/components/DS/menu.html.erb:3-14` and synchronizes them in `app/components/DS/menu_controller.js:64-80`.
- **Keyboard behavior is incomplete for custom controls.** The upload drop zone uses a `div[role=button]` without key handling; tooltips are hover-only; and details summaries explicitly hide focus. Prefer native button/label/details semantics before adding ARIA roles.
- **Mobile constraints are inconsistent.** Most modern controls use `min-w/min-h-[44px]`, and the transactions selection bar has a responsive width, but the global main shell and entries selection bar still impose desktop-sized minimums. Narrow-width behavior must be owned by shared layout primitives, not corrected page by page.
- **Token adoption is partial rather than systemic.** `maybe-design-system.css` provides a substantial semantic palette and dark-mode overrides, but views still use raw color utilities and inline styles. Dynamic category/account colors are legitimate data visualization exceptions; static status and surface colors are not.
- **Chart lifecycle work is duplicated and expensive.** Both time-series and Sankey controllers rebuild SVG trees in ResizeObserver callbacks. Hidden tooltip positioning also remains active in the DS variant. This is a recurring lifecycle/performance concern rather than a single chart defect.
- **Images are inconsistent.** Several list logos correctly use `loading="lazy"` (for example `app/views/holdings/_holding.html.erb:6`), while other account, merchant, and security logo paths omit both `alt` and lazy loading. Preserve the good lazy-loading pattern while standardizing semantics.
- **Detector-style false positives intentionally not counted:** raw hex values in `app/assets/tailwind/maybe-design-system.css` are token definitions; dynamic inline category/account colors are user data visualization; third-party Pickr CSS and system scrollbar overrides are explicitly documented exceptions in `app/assets/tailwind/application.css:140-143`. Fixed-width import mapping tables are wrapped in `overflow-x-auto` (`app/views/import/confirms/_mappings.html.erb:9-43`) and were not counted as unhandled overflow.

## Positive Findings

- The layout has clear desktop/mobile landmarks and labels: `nav` regions and the mobile drawer are explicitly labeled in `app/views/layouts/application.html.erb:44-65` and `app/views/layouts/application.html.erb:81-83`.
- The shared DS button component normalizes 44px minimum icon targets for its sizes (`app/components/DS/buttonish.rb:37-54`), and many newer controls use that convention.
- Forms generally use a styled builder with visible labels, required indicators, and native input types. The money field explicitly associates labels and required markers (`app/views/shared/_money_field.html.erb:10-37`).
- The menu component has a solid baseline for accessible state synchronization and Escape-to-close behavior (`app/components/DS/menu_controller.js:57-80`).
- Native disclosure elements are used extensively for expandable account groups and plaid/account sections, preserving browser keyboard semantics instead of replacing them with click-only divs.
- Chart and empty-state regions have started to receive semantic descriptions (`role="status"`, `role="img"`, and `aria-label`), providing a foundation for richer text alternatives.
- Lazy loading is already applied to several remote or attached images (`app/views/holdings/_holding.html.erb:6`, `app/views/plaid_items/_plaid_item.html.erb:10`), and chart resize observation is preferable to hard-coded one-time dimensions.
- The visual system’s token file has explicit dark-mode semantic overrides and reduced-motion intent, so the remediation path is consolidation and refinement rather than a new theming architecture.

## Recommended Actions

1. **[P1] `$impeccable harden`**: Fix icon-only names/states, mobile drawer focus containment, upload keyboard activation, filter labels, chart text alternatives, dialog close focus, and repeated small copy/edit targets.
2. **[P1] `$impeccable adapt`**: Remove the unconditional `min-w-[480px]` shell constraint, make the entries selection bar fluid on mobile, and verify narrow viewports with increased text size.
3. **[P1] `$impeccable colorize`**: Migrate static raw status/surface colors to semantic DS tokens and add complete dark-mode variants, starting with Redis errors, imports, plaid, and chat errors.
4. **[P1] `$impeccable clarify`**: Restore the password-change heading output and check page landmarks for other non-output translation calls.
5. **[P2] `$impeccable optimize`**: Coalesce D3 ResizeObserver redraws, stop hidden tooltip auto-updates, fix Turbo listener cleanup, and lazy-load heavy chart controllers.
6. **[P2] `$impeccable animate`**: Replace the global reduced-motion kill switch with state-preserving, component-level alternatives.
7. **[P2] `$impeccable polish`**: Re-run the complete UI pass after the structural fixes to align remaining spacing, icon, contrast, and component variants, then re-run `$impeccable audit`.

You can ask me to run these one at a time, all at once, or in any order you prefer.

Re-run `$impeccable audit` after fixes to see your score improve.
