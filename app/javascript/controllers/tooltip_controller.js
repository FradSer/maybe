import {
  autoUpdate,
  computePosition,
  flip,
  offset,
  shift,
} from "@floating-ui/dom";
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tooltip"];
  static values = {
    placement: { type: String, default: "top" },
    offset: { type: Number, default: 10 },
    crossAxis: { type: Number, default: 0 },
    alignmentAxis: { type: Number, default: null },
  };

  connect() {
    this._cleanup = null;
    this.boundUpdate = this.update.bind(this);
    if (!this.tooltipTarget.id) {
      const randomSuffix =
        typeof crypto !== "undefined" && crypto.randomUUID
          ? crypto.randomUUID()
          : Math.random().toString(36).slice(2, 10);
      this.tooltipTarget.id = `tooltip-${randomSuffix}`;
    }
    if (!this.element.hasAttribute("tabindex")) {
      this.element.tabIndex = 0;
    }
    const visibleText = Array.from(this.element.childNodes)
      .filter((node) => node !== this.tooltipTarget)
      .map((node) => node.textContent || "")
      .join("")
      .trim();
    if (!this.element.hasAttribute("aria-label") && !visibleText) {
      this.element.setAttribute("aria-label", "More information");
    }
    this.element.setAttribute("aria-describedby", this.tooltipTarget.id);
    this.addEventListeners();
  }

  disconnect() {
    this.removeEventListeners();
    this.stopAutoUpdate();
  }

  addEventListeners() {
    this.element.addEventListener("mouseenter", this.show);
    this.element.addEventListener("mouseleave", this.hide);
    this.element.addEventListener("focusin", this.show);
    this.element.addEventListener("focusout", this.handleFocusout);
    this.element.addEventListener("keydown", this.handleKeydown);
  }

  removeEventListeners() {
    this.element.removeEventListener("mouseenter", this.show);
    this.element.removeEventListener("mouseleave", this.hide);
    this.element.removeEventListener("focusin", this.show);
    this.element.removeEventListener("focusout", this.handleFocusout);
    this.element.removeEventListener("keydown", this.handleKeydown);
  }

  show = () => {
    this.tooltipTarget.style.display = "block";
    this.startAutoUpdate();
    this.update(); // Ensure immediate update when shown
  };

  hide = () => {
    this.tooltipTarget.style.display = "none";
    this.stopAutoUpdate();
  };

  handleFocusout = (event) => {
    if (!this.element.contains(event.relatedTarget)) this.hide();
  };

  handleKeydown = (event) => {
    if (event.key === "Escape") this.hide();
  };

  startAutoUpdate() {
    if (!this._cleanup) {
      this._cleanup = autoUpdate(
        this.element,
        this.tooltipTarget,
        this.boundUpdate,
      );
    }
  }

  stopAutoUpdate() {
    if (this._cleanup) {
      this._cleanup();
      this._cleanup = null;
    }
  }

  update() {
    // Update position even if not visible, to ensure correct positioning when shown
    computePosition(this.element, this.tooltipTarget, {
      placement: this.placementValue,
      middleware: [
        offset({
          mainAxis: this.offsetValue,
          crossAxis: this.crossAxisValue,
          alignmentAxis: this.alignmentAxisValue,
        }),
        flip(),
        shift({ padding: 5 }),
      ],
    }).then(({ x, y, placement, middlewareData }) => {
      Object.assign(this.tooltipTarget.style, {
        left: `${x}px`,
        top: `${y}px`,
      });
    });
  }
}
