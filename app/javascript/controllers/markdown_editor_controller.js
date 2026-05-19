import { Controller } from "@hotwired/stimulus"
import { Editor } from "tiny-markdown-editor"

export default class extends Controller {
  static targets = ["hiddenField", "textarea", "preview", "editTab", "previewTab", "editorArea", "fileInput", "uploadButton", "uploadOverlay"]
  static values = { initialContent: String, previewUrl: String, uploadUrl: String, uploadPrefix: String }

  connect() {
    this.uploadCount = 0
    this.editor = new Editor({ textarea: this.textareaTarget, content: this.initialContentValue })
    this.editor.addEventListener("change", (e) => {
      if (this.hasHiddenFieldTarget) this.hiddenFieldTarget.value = e.content
    })
    if (this.hasHiddenFieldTarget) this.hiddenFieldTarget.value = this.initialContentValue
    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("turbo:submit-end", (event) => {
        if (event.detail.success) this.clearEditor()
      })
    }
  }

  disconnect() {
    this.editor = null
  }

  preventFocusLoss(event) {
    event.preventDefault()
  }

  showEdit() {
    this.editorAreaTarget.classList.remove("hidden")
    this.previewTarget.classList.add("hidden")
    this.editTabTarget.classList.add("border-blue-500", "text-slate-700")
    this.editTabTarget.classList.remove("border-transparent", "text-slate-500")
    this.previewTabTarget.classList.add("border-transparent", "text-slate-500")
    this.previewTabTarget.classList.remove("border-blue-500", "text-slate-700")
  }

  async showPreview() {
    const content = this.hasHiddenFieldTarget ? this.hiddenFieldTarget.value : this.initialContentValue
    this.previewTarget.innerHTML = '<span class="text-slate-400 text-sm">Loading...</span>'
    this.editorAreaTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")
    this.editTabTarget.classList.add("border-transparent", "text-slate-500")
    this.editTabTarget.classList.remove("border-blue-500", "text-slate-700")
    this.previewTabTarget.classList.add("border-blue-500", "text-slate-700")
    this.previewTabTarget.classList.remove("border-transparent", "text-slate-500")
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(this.previewUrlValue, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": token },
      body: new URLSearchParams({ text: content })
    })
    this.previewTarget.innerHTML = await response.text()
  }

  bold() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("bold", state.bold !== true)
  }

  italic() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("italic", state.italic !== true)
  }

  strikethrough() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("strikethrough", state.strikethrough !== true)
  }

  insertLink() {
    if (this.editor.isInlineFormattingAllowed()) this.editor.wrapSelection("[", "]()")
  }

  insertQuote() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("blockquote", state.blockquote !== true)
    this.#collapseSelection()
  }

  insertCode() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("code", state.code !== true)
  }

  insertUnorderedList() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("ul", state.ul !== true)
    this.#collapseSelection()
  }

  insertOrderedList() {
    const state = this.editor.getCommandState()
    this.editor.setCommandState("ol", state.ol !== true)
    this.#collapseSelection()
  }

  #collapseSelection() {
    const pos = this.editor.getSelection(true)
    if (pos) this.editor.setSelection(pos)
  }

  insertTable() {
    this.editor.paste("\n\n|  |  |  |\n| --- | --- | --- |\n|  |  |  |\n\n")
  }

  insertHr() {
    this.editor.paste("\n\n---\n\n")
  }

  attachFile() {
    this.fileInputTarget.click()
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file) this.uploadFile(file)
    event.target.value = ""
  }

  handlePaste(event) {
    if (!this.uploadUrlValue) return
    const files = Array.from(event.clipboardData?.files || [])
    if (files.length === 0) return
    event.preventDefault()
    files.forEach(file => this.uploadFile(file))
  }

  async uploadFile(file) {
    if (!this.uploadUrlValue) return
    const button = this.hasUploadButtonTarget ? this.uploadButtonTarget : null
    if (button) button.disabled = true
    this.uploadCount++
    if (this.hasUploadOverlayTarget) this.uploadOverlayTarget.classList.remove("hidden")
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body = new FormData()
    body.append("file", file)
    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": token, "Accept": "application/json" },
        body
      })
      const data = await response.json()
      if (data?.link?.url) {
        const prefix = this.uploadPrefixValue
        const url = prefix ? `${prefix}${data.link.url}` : data.link.url
        const isImage = file.type.startsWith("image/")
        this.editor.paste(isImage ? `![${data.link.alt}](${url})` : `[${data.link.alt}](${url})`)
      }
    } finally {
      this.uploadCount--
      if (this.uploadCount === 0 && this.hasUploadOverlayTarget) this.uploadOverlayTarget.classList.add("hidden")
      if (button) button.disabled = false
    }
  }

  clearEditor() {
    this.editor.setContent("")
    if (this.hasHiddenFieldTarget) this.hiddenFieldTarget.value = ""
    this.showEdit()
  }
}
