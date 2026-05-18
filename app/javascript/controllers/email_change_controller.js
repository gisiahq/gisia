import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "tip"]

  connect() {
    this.originalValue = this.inputTarget.value
  }

  show() {
    this.tipTarget.classList.remove("hidden")
  }

  hide() {
    if (this.inputTarget.value === this.originalValue) {
      this.tipTarget.classList.add("hidden")
    }
  }
}
