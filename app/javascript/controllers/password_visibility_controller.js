import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-visibility"
export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"];

  connect() {
    this.hideIconTarget.classList.add("hidden");
    this.updateButtonLabel();
  }

  toggle() {
    const input = this.inputTarget;
    const type = input.type === "password" ? "text" : "password";
    input.type = type;

    this.showIconTarget.classList.toggle("hidden");
    this.hideIconTarget.classList.toggle("hidden");
    this.updateButtonLabel();
  }

  updateButtonLabel() {
    const button = this.element.querySelector("button");
    if (!button) return;
    const showing = this.inputTarget.type === "text";
    button.setAttribute(
      "aria-label",
      showing ? "Hide password" : "Show password",
    );
    button.setAttribute("aria-pressed", String(showing));
  }
}
