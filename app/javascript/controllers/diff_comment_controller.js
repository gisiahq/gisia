import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["commentForm"]

  connect() {
    this.handleClick = this.handleClick.bind(this)
    this.handleMousedown = this.handleMousedown.bind(this)
    this.element.addEventListener('click', this.handleClick)
    this.element.addEventListener('mousedown', this.handleMousedown)
  }

  disconnect() {
    this.element.removeEventListener('click', this.handleClick)
    this.element.removeEventListener('mousedown', this.handleMousedown)
  }

  handleMousedown(event) {
    if (event.shiftKey && this.activeFormWrapper() && this.rangeTargetRow(event)) {
      event.preventDefault()
    }
  }

  handleClick(event) {
    if (event.shiftKey && this.activeFormWrapper()) {
      const row = this.rangeTargetRow(event)
      if (row) {
        event.preventDefault()
        this.extendRange(row)
        return
      }
    }

    const button = event.target.closest('button[data-line-code][title="Add comment"]')
    if (!button) return

    this.showCommentForm(event, button)
  }

  rangeTargetRow(event) {
    const target = event.target.closest('[data-line-gutter], button[data-line-code]')
    if (!target) return null

    const row = target.closest('[data-diff-line]')
    if (!row || !row.querySelector('button[data-line-code]')) return null

    return row
  }

  showCommentForm(event, button) {
    event.preventDefault()
    const lineCode = button.dataset.lineCode
    const lineType = button.dataset.lineType

    const lineRow = button.closest('.group.relative')

    this.hideAllCommentForms()

    this.anchorRow = lineRow
    this.anchorButton = button
    this.insertCommentForm(lineRow, lineCode, lineType)
    this.highlightRange(lineRow, lineRow)

    button.style.opacity = '0'
  }

  insertCommentForm(lineRow, lineCode, lineType) {
    const existingForm = this.element.querySelector(`#comment-form-${lineCode}`)
    if (existingForm) {
      existingForm.remove()
    }

    const formContainer = document.createElement('div')
    formContainer.className = 'diff-comment-form-wrapper'
    formContainer.innerHTML = `
      <div class="border-t border-b border-gray-300 bg-gray-50 p-4 w-full" id="comment-form-${lineCode}"
           data-start-line-code="${lineCode}" data-start-line-type="${lineType}"
           data-end-line-code="${lineCode}" data-end-line-type="${lineType}">
        <div class="mb-3 flex items-center gap-3">
          <span class="text-xs text-gray-700 comment-range-label">
            Commenting on this line ${this.lineBadge(this.displayNumberFromCode(lineCode, lineType))}
          </span>
          <span class="text-xs text-gray-400 flex items-center gap-1 select-none">
            <kbd class="px-1.5 py-0.5 text-xs font-sans font-medium text-gray-500 bg-white border border-gray-300 rounded">Shift</kbd>
            <span>+ click select multiple lines</span>
          </span>
        </div>
        <div class="mb-4">
          <textarea placeholder="Add a comment..."
                   class="w-full p-3 border border-gray-300 rounded-md resize-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                   rows="4"></textarea>
        </div>
        <div class="flex items-center justify-between">
          <div class="text-xs text-gray-500">
            Markdown is supported
          </div>
          <div class="flex gap-2">
            <button type="button" class="px-3 py-1 text-sm text-gray-600 hover:text-gray-800 cancel-comment">
              Cancel
            </button>
            <button type="button" class="px-4 py-2 bg-blue-600 text-white text-sm rounded-md hover:bg-blue-700 submit-comment">
              Add to review
            </button>
          </div>
        </div>
      </div>
    `

    lineRow.insertAdjacentElement('afterend', formContainer)

    const textarea = formContainer.querySelector('textarea')
    textarea.focus()

    formContainer.querySelector('.cancel-comment').addEventListener('click', () => {
      this.cancelComment()
    })

    formContainer.querySelector('.submit-comment').addEventListener('click', () => {
      this.submitComment()
    })
  }

  extendRange(row) {
    const anchor = this.anchorRow
    const wrapper = this.activeFormWrapper()
    if (!anchor || !anchor.isConnected || !wrapper) return

    const [startRow, endRow] = this.orderRows(anchor, row)
    const form = wrapper.firstElementChild

    form.dataset.startLineCode = startRow.dataset.lineCode
    form.dataset.startLineType = this.rowLineType(startRow)
    form.dataset.endLineCode = endRow.dataset.lineCode
    form.dataset.endLineType = this.rowLineType(endRow)
    form.id = `comment-form-${endRow.dataset.lineCode}`

    endRow.insertAdjacentElement('afterend', wrapper)
    this.highlightRange(startRow, endRow)
    this.updateRangeLabel(form, startRow, endRow)

    wrapper.querySelector('textarea').focus()
  }

  orderRows(a, b) {
    if (a === b) return [a, a]

    const following = a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING
    return following ? [a, b] : [b, a]
  }

  rowLineType(row) {
    return row.querySelector('button[data-line-code]').dataset.lineType
  }

  updateRangeLabel(form, startRow, endRow) {
    const label = form.querySelector('.comment-range-label')
    if (!label) return

    if (startRow === endRow) {
      label.innerHTML = `Commenting on this line ${this.lineBadge(this.displayLineNumber(startRow))}`
    } else {
      const startNum = this.displayLineNumber(startRow)
      const endNum = this.displayLineNumber(endRow)
      label.innerHTML = `Commenting on lines ${this.lineBadge(`${startNum}&ndash;${endNum}`)}`
    }
  }

  lineBadge(text) {
    return `<span class="inline-flex items-center px-1.5 py-0.5 rounded bg-gray-200 text-gray-600 font-mono text-xs font-semibold align-middle">${text}</span>`
  }

  displayLineNumber(row) {
    return this.displayNumberFromCode(row.dataset.lineCode, this.rowLineType(row))
  }

  displayNumberFromCode(lineCode, lineType) {
    const parts = lineCode.split('_')
    return lineType === 'deletion' ? parts[1] : parts[2]
  }

  highlightRange(startRow, endRow) {
    this.clearHighlight()

    const rows = Array.from(this.element.querySelectorAll('[data-diff-line]'))
    const startIndex = rows.indexOf(startRow)
    const endIndex = rows.indexOf(endRow)
    if (startIndex === -1 || endIndex === -1) return

    rows.slice(startIndex, endIndex + 1).forEach(row => {
      row.classList.add('diff-line-range-selected')
    })
  }

  clearHighlight() {
    this.element.querySelectorAll('.diff-line-range-selected').forEach(row => {
      row.classList.remove('diff-line-range-selected')
    })
  }

  cancelComment() {
    const wrapper = this.activeFormWrapper()
    if (wrapper) {
      wrapper.remove()
    }

    this.clearHighlight()

    if (this.anchorButton) {
      this.anchorButton.style.opacity = ''
    }
    this.anchorRow = null
    this.anchorButton = null
  }

  async submitComment() {
    const wrapper = this.activeFormWrapper()
    if (!wrapper) return

    const form = wrapper.firstElementChild
    const textarea = form.querySelector('textarea')
    const content = textarea.value.trim()

    if (!content) {
      textarea.focus()
      return
    }

    const submitButton = form.querySelector('.submit-comment')
    const originalText = submitButton.textContent
    submitButton.textContent = 'Submitting...'
    submitButton.disabled = true

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const apiEndpoint = this.element.dataset.apiEndpoint

      if (!apiEndpoint) {
        console.error('API endpoint not found')
        submitButton.disabled = false
        submitButton.textContent = originalText
        return
      }

      const position = this.buildPositionData(form)

      const response = await fetch(apiEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'text/vnd.turbo-stream.html, application/json'
        },
        body: JSON.stringify({
          draft_note: {
            note: content,
            line_code: form.dataset.endLineCode,
            position: JSON.stringify(position)
          }
        })
      })

      const turboStreamContent = await response.text()
      this.clearHighlight()
      if (this.anchorButton) {
        this.anchorButton.style.opacity = ''
      }
      this.anchorRow = null
      this.anchorButton = null
      Turbo.renderStreamMessage(turboStreamContent)
    } catch (error) {
      console.error('Error submitting comment:', error)
      alert('Failed to submit comment')
      submitButton.disabled = false
      submitButton.textContent = originalText
    }
  }

  buildPositionData(form) {
    const start = this.lineLocation(form.dataset.startLineCode, form.dataset.startLineType)
    const end = this.lineLocation(form.dataset.endLineCode, form.dataset.endLineType)
    if (!start || !end) return null

    return {
      base_sha: this.element.dataset.baseSha,
      start_sha: this.element.dataset.startSha,
      head_sha: this.element.dataset.headSha,
      old_path: this.element.dataset.oldPath,
      new_path: this.element.dataset.newPath,
      position_type: 'text',
      old_line: end.old_line,
      new_line: end.new_line,
      line_range: { start: start, end: end },
      ignore_whitespace_change: false
    }
  }

  lineLocation(lineCode, lineType) {
    const parts = lineCode.split('_')
    if (parts.length < 3) return null

    const rawOldLine = parseInt(parts[1])
    const rawNewLine = parseInt(parts[2])

    return {
      line_code: lineCode,
      type: lineType === 'addition' ? 'new' : lineType === 'deletion' ? 'old' : null,
      old_line: lineType === 'addition' ? null : rawOldLine,
      new_line: lineType === 'deletion' ? null : rawNewLine
    }
  }

  activeFormWrapper() {
    const wrapper = this.element.querySelector('.diff-comment-form-wrapper')
    if (wrapper && !wrapper.firstElementChild) {
      wrapper.remove()
      return null
    }
    return wrapper
  }

  hideAllCommentForms() {
    this.clearHighlight()
    this.element.querySelectorAll('.diff-comment-form-wrapper').forEach(form => {
      form.remove()
    })
    if (this.anchorButton) {
      this.anchorButton.style.opacity = ''
    }
  }
}
