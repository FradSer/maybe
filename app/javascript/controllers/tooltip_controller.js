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
    this.tooltipTarget.id ||= `tooltip-${crypto.randomUUID()}`;
    this.element.tabIndex ||= 0;
    this.element.setAttribute("aria-label", this.element.getAttribute("aria-label") || "More information");
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
