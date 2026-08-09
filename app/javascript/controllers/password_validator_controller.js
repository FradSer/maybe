import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-validator"
export default class extends Controller {
  static targets = ["input", "requirementType", "blockLine", "confirmation", "confirmationMatch", "confirmationMismatch"];

  connect() {
    this.validate();
  }

  validate() {
    const password = this.inputTarget.value;
    let requirementsMet = 0;

    // Check each requirement and count how many are met
    const lengthValid = password.length >= 8;
    const caseValid = /[A-Z]/.test(password) && /[a-z]/.test(password);
    const numberValid = /\d/.test(password);
    const specialValid = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    // Update individual requirement text
    this.validateRequirementText("length", lengthValid);
    this.validateRequirementText("case", caseValid);
    this.validateRequirementText("number", numberValid);
    this.validateRequirementText("special", specialValid);

    // Count total requirements met
    if (lengthValid) requirementsMet++;
    if (caseValid) requirementsMet++;
    if (numberValid) requirementsMet++;
    if (specialValid) requirementsMet++;

    // Update block lines sequentially
    this.updateBlockLines(requirementsMet);

    // Re-validate confirmation if it has a value
    if (this.hasConfirmationTarget && this.confirmationTarget.value.length > 0) {
      this.validateConfirmation();
    }
  }

  validateConfirmation() {
    if (!this.hasConfirmationTarget) return;

    const password = this.inputTarget.value;
    const confirmation = this.confirmationTarget.value;
    const match = password === confirmation && password.length > 0;

    // Toggle visual feedback on the confirmation input
    this.confirmationTarget.classList.remove("border-destructive", "border-success", "text-destructive");
    if (confirmation.length > 0) {
      if (match) {
        this.confirmationTarget.classList.add("border-success");
      } else {
        this.confirmationTarget.classList.add("border-destructive");
      }
    }

    // Toggle confirmation match status messages
    this.hasConfirmationMatchTarget && this.confirmationMatchTarget.classList.toggle("hidden", !match);
    this.hasConfirmationMismatchTarget && this.confirmationMismatchTarget.classList.toggle(
      "hidden", match || confirmation.length === 0
    );
  }

  validateRequirementText(type, isValid) {
    this.requirementTypeTargets.forEach((target) => {
      if (target.dataset.requirementType === type) {
        if (isValid) {
          target.classList.remove("text-secondary");
          target.classList.add("text-success");
        } else {
          target.classList.remove("text-success");
          target.classList.add("text-secondary");
        }
      }
    });
  }

  updateBlockLines(requirementsMet) {
    // Update block lines sequentially based on total requirements met
    this.blockLineTargets.forEach((line, index) => {
      if (index < requirementsMet) {
        line.classList.remove("bg-surface-inset");
        line.classList.add("bg-success");
      } else {
        line.classList.remove("bg-success");
        line.classList.add("bg-surface-inset");
      }
    });
  }
}
