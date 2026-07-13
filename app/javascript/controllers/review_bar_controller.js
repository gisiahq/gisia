import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new ResizeObserver(() => this.updatePadding())
    this.observer.observe(this.element)
    this.updatePadding()
  }

  disconnect() {
    this.observer.disconnect()
    document.body.style.paddingBottom = ""
  }

  updatePadding() {
    document.body.style.paddingBottom = `${this.element.offsetHeight}px`
  }
}
