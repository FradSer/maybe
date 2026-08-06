---
target: budgets
total_score: 23
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
p2_count: 5
timestamp: 2026-08-06T08-21-45Z
slug: app-views-budgets-show-html-erb
---
# UX Critique: Maybe — All Major Surfaces

**Method:** Dual-agent (7 parallel design reviews · 1 detector scan)

**Detector:** 0 findings — all technical quality issues resolved.

## Design Health Score

| # | Heuristic | Avg Score | Key Issue |
|---|-----------|-----------|-----------|
| 1 | Visibility of System Status | 2.7/4 | No data freshness indicators; no chat response cancellation |
| 2 | Match System / Real World | 2.7/4 | "Bootstrap" jargon persists; "Assets/Debts" terms may confuse |
| 3 | User Control and Freedom | 2.3/4 | Shutdown banner undismissable; no undo on toggle; 4-step onboarding with no skip |
| 4 | Consistency and Standards | 2.7/4 | Password meter on register but not on reset; inconsistent hover patterns |
| 5 | Error Prevention | 2.3/4 | No password confirmation; no "remember me"; disabled checkboxes without explanation |
| 6 | Recognition Rather Than Recall | 2.7/4 | AI assistant hidden behind unlabeled icon; no chat previews; no search history |
| 7 | Flexibility and Efficiency | 1.7/4 | Zero keyboard shortcuts anywhere; no bulk category editing; no saved searches |
| 8 | Aesthetic and Minimalist Design | 3.3/4 | Clean and professional; weight bar visualization is confusing |
| 9 | Error Recovery | 1.7/4 | Generic error messages; no field-level validation; form errors at top only |
| 10 | Help and Documentation | 1.0/4 | No contextual help, tooltips, or documentation anywhere |
| **Total** | | **23/40** | **Acceptable** |

## Design Specificity Verdict

**Scoring: 7/10 — coherent but not yet distinctive.** Consistent design system, professional spacing, but lacks moments of personality or brand character. Auth pages are particularly generic.

## What's Working

1. **Dashboard information hierarchy.** Three-zone layout (net worth → balance sheet → cashflow) is logical. Expandable details give users control over data density.
2. **Consistent design system.** Every surface uses text-primary, text-secondary, bg-container, shadow-border-xs, rounded-xl consistently.
3. **Password validator on registration.** Real-time strength meter is the most delightful interaction in the product.

## Priority Issues

### P1 — Cross-Surface

**[P1] No keyboard shortcuts anywhere** — All surfaces. Power users must click through every action. Fix: Add global shortcuts (n, /, g→d/t/a/b).

**[P1] No contextual help or documentation** — All surfaces. Zero tooltips, help icons, or inline explanations. The Sankey, weight bars, filter tabs — none explained.

**[P1] AI assistant is undiscoverable on desktop** — Chats. mobile_only: true means Assistant tab only appears in mobile bottom nav. Desktop: hidden behind unlabeled panel-right icon.

### P2 — Surface-Specific

**[P2] Shutdown banner is undismissable** — Dashboard. Takes prime real estate on every page load.

**[P2] Weight bar visualization is misleading** — Dashboard. 10-segment bar with ceil(weight/10) rounding makes 1% and 9% indistinguishable.

**[P2] No data freshness on dashboard** — Dashboard. No "last updated" timestamp.

**[P2] Chat has no search, no cancel, no previews** — Chats. No way to find past conversations, cancel responses, or see message previews.

**[P2] Onboarding has no skip option and no step indicator** — Onboarding. 4 mandatory steps, zero progress indicator on mobile.

### P3 — Polish

- No password confirmation on registration
- No "remember me" on login
- Disabled transfer checkboxes without explanation
- Inconsistent password meter (register only)
- Chat consent overlay has no dismiss option
- No empty state illustrations anywhere

## Persona Red Flags

**Alex (Power User):** Zero keyboard shortcuts, no bulk operations beyond transactions, no saved searches, no way to cancel AI responses.

**Jordan (First-Timer):** "Bootstrap" button, "Assets/Debts" tabs, "Budgeted vs Actuals" terminology — all unexplained. No tooltips, no help.

**Sam (Accessibility):** Errors at top of form with no field-level aria-describedby. No autofocus on login. Password visibility toggle works but error recovery is weak.

**Casey (Mobile User):** Onboarding has no step indicator. Filter menu uses horizontal scroll with no overflow affordance. Selection bar position inconsistent.
