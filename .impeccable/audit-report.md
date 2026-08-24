# Maybe UI Technical Audit — Re-audit (2026-08-24)

Baseline: `audit-report.baseline.md` (2026-08-21, 7/20 Poor). This re-audit covers the two polish rounds and the remediation rounds that followed. Verification combines source inspection, mechanical detector passes, live browser checks, WCAG contrast sampling, responsive checks, reduced-motion emulation, screenshots, and resource-load evidence.

## Audit Health Score

| # | Dimension | Baseline | Now | Key Finding |
|---|-----------|----------|-----|-------------|
| 1 | Accessibility | 1/4 | **4/4** | Named controls, keyboard paths, focus containment, chart text equivalents, decorative initials, and live contrast checks verified |
| 2 | Performance | 2/4 | **4/4** | rAF-coalesced chart redraws, lazy controller loading, listener leaks closed; d3 absent on settings and loaded on dashboard only |
| 3 | Responsive Design | 1/4 | **4/4** | Global 480px floor removed, fluid selection bar, 44px targets, and 375px no-overflow check verified |
| 4 | Theming | 1/4 | **4/4** | Light/dark contrast scans passed across dashboard, transactions, budgets, chats, and account detail; screenshots captured |
| 5 | Implementation Integrity | 2/4 | **4/4** | Drift eliminated, dead code removed, semantic DS components adopted, detector clean across all passes |
| **Total** | | **7/20 Poor** | **20/20 Excellent** | Browser-verified final state |

## Implementation Integrity Verdict

**Pass.** The implementation now expresses the committed "Financial Cockpit" system: semantic tokens carry all status color with dark-mode pairs, shared DS components own tab/menu/dialog semantics, decorative artifacts (gold gradient text, shutdown banner) are gone, and the mechanical detector returns zero findings across every changed surface.

## Resolution Ledger (baseline → now)

### P1 (9/9 resolved)
| Finding | Evidence of resolution |
|---|---|
| Unnamed icon controls across shell | aria labels at call sites; DS tabs/menuitem/dialog roles; layout sidebar+AI controls named |
| Mobile drawer not keyboard-contained | `app/javascript/controllers/app_layout_controller.js`: inert toggling, focus return to hamburger, focus trap |
| Upload dropzone click-only | keydown activation wired in `app/views/import/uploads/show.html.erb` |
| Filter fields unlabeled | search field + amount/date filter fields carry programmatic labels |
| Charts without textual data | role="img" + aria-label + sr-only captioned data tables in both dashboard chart partials |
| Global 480px min-width | removed from `app/views/layouts/application.html.erb` main region |
| Selection bar fixed width | fluid; md breakpoint no longer hard-codes 420px |
| Redis error bypassed tokens | page fully tokenized (`text-primary`/`text-secondary`, zero raw status colors) |
| Empty password heading | `<%=` output restored |

### P2 (11/11 resolved or dispositioned)
Focus indicators on disclosures; tooltip keyboard/focus handling; reduced-motion state-preserving replacement; D3 resize coalescing (rAF + 2px threshold); hidden-tooltip autoUpdate lifecycle; file-upload listener leak (bound refs); eager controller loading (lazy switch, d3 deferred); image alt text; raw colors on imports/plaid/chats/mappings/upgrade/tool_calls/import-rows (theme-dark pairs); dialog close button tab-reachable; sub-44px copy/edit actions (mfa, profiles, accounts row, entries selection bar).

### Browser verification ledger
- Contrast sampling passed in both themes on dashboard, transactions, budgets, chats, and account detail after filtering decorative `aria-hidden` initials.
- Trend text uses theme-aware AA tokens: positive `green-800`/`green-500`, negative `red-700`/`red-400`, flat `gray-500`/`gray-400`.
- Reduced-motion emulation confirmed movement transitions are removed while 150ms color/opacity feedback remains.
- Resource evidence confirmed d3 is absent on `/settings` and loaded on the chart-bearing dashboard.
- 375×812 viewport confirmed no horizontal overflow; drawer bounds were off-canvas by design.
- Desktop light/dark and mobile screenshots were captured and visually reviewed during the bounded browser pass; temporary files were removed after review.

### Deliberate exceptions
- `transactions/searches/filters/_badge.html.erb` blue chips: data-driven type→color mapping (audit-sanctioned category-color exception)
- `accounts/new/_method_selector.html.erb`, `_account_type.html.erb`: `focus:outline-hidden` paired with visible bg/border focus alternatives (WCAG 2.4.7 satisfied)

## Remaining Watch Items (P3-level backlog)

1. Chart SVGs are coalesced rebuilds, not incremental geometry updates — fine at current scale, revisit if dashboards grow many large series.
2. Polisher's deliberate scope skips from round 1 remain open as backlog: global keyboard-shortcut expansion, low-traffic empty states, bulk-operation affordances, disabled-transfer explanation.
3. `erb_lint` is not installed locally; ERB changes were verified by browser rendering, source inspection, Ruby/Node syntax checks, and detector scans. The Rails fixture database currently has pre-existing foreign-key violations, so the model test command cannot initialize fixtures.

## Positive Findings

- The DS component layer (tabs, menu, dialog, toggle) now carries correct ARIA semantics once, instead of per-view patches.
- Dark-mode coverage moved from "missing" to systematically paired via the established `theme-dark:` recipe used by DS::Alert itself.
- Dead code (shutdown banner + its controller) removed rather than maintained.

## Final Disposition

The requested audit target is complete at **20/20**. The remaining items are explicitly P3 backlog work and do not block this audit result.
