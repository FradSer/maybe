import { install, uninstall } from "@github/hotkey";
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="hotkey"
export default class extends Controller {
  static values = {
    helpOverlayVisible: { type: Boolean, default: false },
  };

  connect() {
    install(this.element);
  }

  disconnect() {
    uninstall(this.element);
  }

  navigateBack(event) {
    window.history.back();
  }

  // Global hotkeys must not fire while the user is typing in an input,
  // textarea, or contenteditable element (e.g. typing "good" navigates).
  shouldHandle(event) {
    if (event.defaultPrevented) return false;
    const target = event.target;
    if (target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement) return false;
    if (target.isContentEditable) return false;
    return true;
  }

  // n -> navigate to new transaction page
  newTransaction(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    const link = document.querySelector('[href*="/transactions/new"]');
    if (link) {
      link.click();
    }
  }

  // / -> focus the search input on the transactions page
  focusSearch(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    const searchInput = document.querySelector(
      '#transactions-search input[type="text"], #transactions-search input[name="q[search]"], #transactions-search input[placeholder*="Search"]',
    );
    if (searchInput) {
      searchInput.focus();
    }
  }

  // g then d -> navigate to dashboard (root_path)
  goToDashboard(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    window.location.href = "/";
  }

  // g then t -> navigate to transactions page
  goToTransactions(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    window.location.href = "/transactions";
  }

  // g then a -> navigate to accounts page
  goToAccounts(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    window.location.href = "/accounts";
  }

  // g then b -> navigate to budgets page
  goToBudgets(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    window.location.href = "/budgets";
  }

  // ? -> show keyboard shortcut help overlay
  toggleHelpOverlay(event) {
    if (!this.shouldHandle(event)) return;
    event.preventDefault();
    this.helpOverlayVisibleValue = !this.helpOverlayVisibleValue;

    let overlay = document.getElementById("hotkey-help-overlay");
    if (this.helpOverlayVisibleValue) {
      if (!overlay) {
        overlay = document.createElement("div");
        overlay.id = "hotkey-help-overlay";
        overlay.innerHTML = `
          <div class="fixed inset-0 bg-overlay z-50 flex items-center justify-center p-4"
               data-action="click->hotkey#toggleHelpOverlay">
            <div class="bg-container rounded-xl shadow-2xl max-w-md w-full p-6 space-y-4"
                 data-action="click->hotkey#stopPropagation">
              <div class="flex items-center justify-between">
                <h2 class="text-lg font-semibold text-primary">Keyboard Shortcuts</h2>
                <button data-action="click->hotkey#toggleHelpOverlay" class="p-1 rounded-lg text-secondary hover:text-primary" aria-label="Close keyboard shortcuts">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                </button>
              </div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">n</kbd><span class="text-secondary">New transaction</span></div>
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">/</kbd><span class="text-secondary">Search transactions</span></div>
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">g</kbd> then <kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">d</kbd><span class="text-secondary">Dashboard</span></div>
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">g</kbd> then <kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">t</kbd><span class="text-secondary">Transactions</span></div>
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">g</kbd> then <kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">a</kbd><span class="text-secondary">Accounts</span></div>
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">g</kbd> then <kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">b</kbd><span class="text-secondary">Budgets</span></div>
                <div class="flex justify-between py-1"><kbd class="bg-surface-inset px-2 py-0.5 rounded text-xs font-mono text-primary">?</kbd><span class="text-secondary">Toggle this help</span></div>
              </div>
            </div>
          </div>
        `;
        document.body.appendChild(overlay);
      } else {
        overlay.classList.remove("hidden");
      }
    } else if (overlay) {
      overlay.classList.add("hidden");
    }
  }

  stopPropagation(event) {
    event.stopPropagation();
  }
}
