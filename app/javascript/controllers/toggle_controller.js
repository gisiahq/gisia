import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "label", "swap", "hide"]

  toggle() {
    const hidden = this.contentTarget.classList.toggle("hidden")
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = hidden ? "Compare" : "Hide"
    }
    this.hideTargets.forEach(el => el.classList.toggle("hidden"))
    if (this.hasSwapTarget) {
      this.swapTarget.dataset.toggleClass.split(" ").forEach(name => {
        this.swapTarget.classList.toggle(name)
      })
    }
  }
}
