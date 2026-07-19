import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "fileButton", "viewedCount"]
  static values = { storageKey: String }

  connect() {
    this.reviews = this.loadReviews()
    this.syncAll()
  }

  toggle(event) {
    const { fileIdentifierHash, codeReviewId } = event.currentTarget.dataset

    if (event.currentTarget.checked) {
      this.reviews[fileIdentifierHash] = codeReviewId
    } else {
      delete this.reviews[fileIdentifierHash]
    }

    this.saveReviews()
    this.syncAll()

    if (event.currentTarget.checked) this.advanceToNextUnviewed()
  }

  syncAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = this.reviewed(checkbox.dataset)
    })

    this.fileButtonTargets.forEach((button) => {
      button.classList.toggle("opacity-50", this.reviewed(button.dataset))
    })

    this.updateViewedCount()
  }

  advanceToNextUnviewed() {
    const buttons = this.fileButtonTargets
    const current = this.currentFileIndex()
    const currentPos = buttons.findIndex((button) => parseInt(button.dataset.fileIndex) === current)
    const ordered = buttons.slice(currentPos + 1).concat(buttons.slice(0, currentPos + 1))
    const next = ordered.find((button) => !this.reviewed(button.dataset))

    if (next) next.click()
  }

  currentFileIndex() {
    const visible = this.element.querySelector(".diff-file-container:not(.hidden)")

    return visible ? parseInt(visible.dataset.fileIndex) : 0
  }

  updateViewedCount() {
    if (!this.hasViewedCountTarget) return

    const viewed = this.fileButtonTargets.filter((button) => this.reviewed(button.dataset)).length

    this.viewedCountTarget.textContent = viewed > 0 ? `· ${viewed} viewed` : ""
    this.viewedCountTarget.classList.toggle("hidden", viewed === 0)
  }

  reviewed({ fileIdentifierHash, codeReviewId }) {
    return this.reviews[fileIdentifierHash] === codeReviewId
  }

  loadReviews() {
    try {
      return JSON.parse(localStorage.getItem(this.reviewsKey())) || {}
    } catch {
      return {}
    }
  }

  saveReviews() {
    try {
      if (Object.keys(this.reviews).length === 0) {
        localStorage.removeItem(this.reviewsKey())
      } else {
        localStorage.setItem(this.reviewsKey(), JSON.stringify(this.reviews))
      }
    } catch {
    }
  }

  reviewsKey() {
    return `${this.storageKeyValue}-file-reviews`
  }
}
