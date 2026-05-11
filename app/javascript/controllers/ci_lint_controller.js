import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "validateBtn"]

  connect() {
    this.formTarget.addEventListener("turbo:submit-start", this.onSubmitStart.bind(this))
    this.formTarget.addEventListener("turbo:submit-end", this.onSubmitEnd.bind(this))
  }

  disconnect() {
    this.formTarget.removeEventListener("turbo:submit-start", this.onSubmitStart.bind(this))
    this.formTarget.removeEventListener("turbo:submit-end", this.onSubmitEnd.bind(this))
  }

  onSubmitStart() {
    this.validateBtnTarget.disabled = true
    this.validateBtnTarget.textContent = "Validating…"
  }

  onSubmitEnd() {
    this.validateBtnTarget.disabled = false
    this.validateBtnTarget.textContent = "Validate"
  }
}
