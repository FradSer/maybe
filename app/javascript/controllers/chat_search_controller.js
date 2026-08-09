import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="chat-search"
export default class extends Controller {
  static targets = ["input", "list"];

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim();

    this.listTarget.querySelectorAll("[data-chat-title]").forEach((item) => {
      const title = item.dataset.chatTitle.toLowerCase();
      item.style.display = query === "" || title.includes(query) ? "" : "none";
    });
  }
}
