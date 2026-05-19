import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["placeholder", "editor"]

  connect() {
    if (!this.hasEditorTarget) return
    const form = this.editorTarget.querySelector("form")
    if (form) {
      form.addEventListener("turbo:submit-end", (event) => {
        if (event.detail.success) this.collapse()
      })
    }
  }

  expand() {
    this.placeholderTarget.classList.add("hidden")
    this.editorTarget.classList.remove("hidden")
    const editable = this.editorTarget.querySelector("[contenteditable]")
    if (editable) editable.focus()
  }

  collapse() {
    this.editorTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
  }
}
