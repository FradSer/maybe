import { Controller } from "@hotwired/stimulus";

/**
 * Three-panel responsive layout with staged collapse/restore.
 *
 * Desktop (md+):
 *   [nav-rail 84px] [left-sidebar 320px] [content grow] [right-sidebar 400px]
 *
 * Collapse order (narrowing):   left sidebar first, then right sidebar.
 * Restore order (widening):     right sidebar first, then left sidebar.
 *
 * Key design decisions:
 *   - Sidebars are `flex-shrink: 0` — they never compress.
 *   - Content uses `grow` — it compresses first.
 *   - Measurement uses `window.innerWidth` (NOT ResizeObserver on the flex
 *     container) to avoid feedback loops when collapsing/expanding sidebars
 *     changes the container width.
 *   - A hysteresis buffer (~60px) prevents flapping at the threshold.
 *   - User manual toggles set a "forced" flag that is only released once the
 *     window is clearly wide enough (+100px extra margin).
 *   - Auto-collapse/restore does NOT persist to the server; only manual
 *     toggles update the user preference.
 */
export default class extends Controller {
  static targets = ["leftSidebar", "rightSidebar", "mobileSidebar", "mobileBackdrop"];

  static values = {
    leftSidebarWidth: { type: Number, default: 320 },
    leftSidebarMinWidth: { type: Number, default: 280 },
    rightSidebarWidth: { type: Number, default: 400 },
    rightSidebarMinWidth: { type: Number, default: 360 },
    contentMinWidth: { type: Number, default: 400 },
    userId: Number,
    leftOpen: { type: Boolean, default: true },
    rightOpen: { type: Boolean, default: true },
  };

  // Fixed left nav rail width (must match CSS .app-layout__nav-rail)
  #navWidth = 84;

  // Hysteresis prevents flapping when the window is near the threshold
  #hysteresis = 60;

  // Extra margin before releasing a user-forced flag
  #releaseMargin = 100;

  // RAF-based debounce timer
  #resizeTimer = null;

  // Track which sidebars were collapsed/restored automatically
  #autoCollapsedLeft = false;
  #autoCollapsedRight = false;

  // Track whether the user manually forced a sidebar open/closed
  #userForcedLeft = false;
  #userForcedRight = false;

  // ── Lifecycle ────────────────────────────────────────────────────────

  connect() {
    this.#checkPanels();
    window.addEventListener("resize", this.#onResize);
  }

  disconnect() {
    window.removeEventListener("resize", this.#onResize);
    if (this.#resizeTimer) cancelAnimationFrame(this.#resizeTimer);
  }

  get #isMobile() {
    return window.matchMedia("(max-width: 767px)").matches;
  }

  // ── Mobile drawer ───────────────────────────────────────────────────

  openMobileSidebar() {
    this.mobileSidebarTarget.classList.add("app-layout__drawer--open");
    this.mobileSidebarTarget.setAttribute("aria-hidden", "false");
    this.mobileBackdropTarget.classList.add("opacity-100");
    this.mobileBackdropTarget.classList.remove("opacity-0", "pointer-events-none");
  }

  closeMobileSidebar() {
    this.mobileSidebarTarget.classList.remove("app-layout__drawer--open");
    this.mobileSidebarTarget.setAttribute("aria-hidden", "true");
    this.mobileBackdropTarget.classList.add("opacity-0", "pointer-events-none");
    this.mobileBackdropTarget.classList.remove("opacity-100");
  }

  // ── Desktop sidebar toggle (user-initiated) ─────────────────────────

  toggleLeftSidebar() {
    const open = !this.leftOpenValue;
    this.#autoCollapsedLeft = false;
    this.#userForcedLeft = open;
    this.#setLeftOpen(open, true);
  }

  toggleRightSidebar() {
    const open = !this.rightOpenValue;
    this.#autoCollapsedRight = false;
    this.#userForcedRight = open;
    this.#setRightOpen(open, true);
  }

  // ── Internal state management ───────────────────────────────────────

  #setLeftOpen(open, persist = false) {
    this.leftOpenValue = open;
    this.#applySidebarState(this.leftSidebarTarget, open);
    if (persist) {
      this.#updateUserPreference("show_sidebar", open);
    }
  }

  #setRightOpen(open, persist = false) {
    this.rightOpenValue = open;
    this.#applySidebarState(this.rightSidebarTarget, open);
    if (persist) {
      this.#updateUserPreference("show_ai_sidebar", open);
    }
  }

  #applySidebarState(el, open) {
    el.classList.toggle("app-layout__sidebar--open", open);
    el.classList.toggle("app-layout__sidebar--closed", !open);
  }

  // ── Resize handler (RAF-debounced) ──────────────────────────────────

  #onResize = () => {
    if (this.#resizeTimer) cancelAnimationFrame(this.#resizeTimer);
    this.#resizeTimer = requestAnimationFrame(() => {
      this.#resizeTimer = null;
      this.#checkPanels();
    });
  };

  // ── Panel collapse/restore logic ────────────────────────────────────

  /**
   * Evaluate the available width and decide whether to collapse or restore
   * sidebars. This is called on connect, and on every resize event.
   *
   * Available width = window.innerWidth - fixed nav rail (84px).
   * Sidebars are always flex-shrink:0, so they consume their full width when
   * open. Content gets the remainder and compresses via `grow`.
   *
   * Thresholds:
   *   Both open   →  need LEFT + RIGHT + MIN
   *   Only left   →  need LEFT + MIN
   *   Only right  →  need RIGHT + MIN
   *   Restore adds hysteresis (+H) to prevent flapping.
   */
  #checkPanels() {
    if (this.#isMobile || !this.hasLeftSidebarTarget) return;

    const available = window.innerWidth - this.#navWidth;
    const LEFT = this.leftSidebarWidthValue;
    const RIGHT = this.rightSidebarWidthValue;
    const MIN = this.contentMinWidthValue;
    const H = this.#hysteresis;

    const leftIsOpen = this.leftOpenValue;
    const rightIsOpen = this.rightOpenValue;
    const leftAuto = !this.#userForcedLeft;
    const rightAuto = !this.#userForcedRight;

    // ── Collapse (narrowing): left first, then right ──

    // Both open → need LEFT + RIGHT + MIN
    if (leftIsOpen && rightIsOpen && leftAuto && rightAuto) {
      if (available < LEFT + RIGHT + MIN) {
        this.#autoCollapsedLeft = true;
        this.#setLeftOpen(false);
        return;
      }
    }

    // Only left open → need LEFT + MIN
    if (leftIsOpen && !rightIsOpen && leftAuto) {
      if (available < LEFT + MIN) {
        this.#autoCollapsedLeft = true;
        this.#setLeftOpen(false);
        return;
      }
    }

    // Only right open → need RIGHT + MIN
    if (!leftIsOpen && rightIsOpen && rightAuto) {
      if (available < RIGHT + MIN) {
        this.#autoCollapsedRight = true;
        this.#setRightOpen(false);
        return;
      }
    }

    // ── Restore (widening): right first, then left ──

    // Both closed → restore right first
    if (!leftIsOpen && !rightIsOpen) {
      if (this.#autoCollapsedRight && available >= RIGHT + MIN + H) {
        this.#autoCollapsedRight = false;
        this.#setRightOpen(true);
        return;
      }
      // Then restore left (needs both sidebars' worth of room)
      if (this.#autoCollapsedLeft && available >= LEFT + RIGHT + MIN + H) {
        this.#autoCollapsedLeft = false;
        this.#setLeftOpen(true);
        return;
      }
    }

    // Left closed, right open → try restoring left
    if (!leftIsOpen && rightIsOpen && this.#autoCollapsedLeft) {
      if (available >= LEFT + RIGHT + MIN + H) {
        this.#autoCollapsedLeft = false;
        this.#setLeftOpen(true);
        return;
      }
    }

    // ── Release user-forced flags ──

    if (this.#userForcedLeft && available >= LEFT + RIGHT + MIN + H + this.#releaseMargin) {
      this.#userForcedLeft = false;
    }
    if (this.#userForcedRight && available >= RIGHT + MIN + H + this.#releaseMargin) {
      this.#userForcedRight = false;
    }
  }

  // ── Persistence ─────────────────────────────────────────────────────

  #updateUserPreference(field, value) {
    fetch(`/users/${this.userIdValue}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: new URLSearchParams({
        [`user[${field}]`]: value,
      }).toString(),
    });
  }
}