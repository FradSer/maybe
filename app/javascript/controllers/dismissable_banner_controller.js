import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dismissable-banner"
export default class extends Controller {
  static values = {
    key: { type: String, default: "dismissed-banner" },
  };

  connect() {
    if (sessionStorage.getItem(this.keyValue) === "true") {
      this.element.remove();
    }
  }

  dismiss() {
    sessionStorage.setItem(this.keyValue, "true");
    this.element.remove();
  }
}