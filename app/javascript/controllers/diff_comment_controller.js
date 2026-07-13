import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["commentForm"]

  connect() {
    this.setupCommentButtons()
  }

  setupCommentButtons() {
    // Add click handlers to all comment buttons
    this.element.querySelectorAll('[data-line-code]').forEach(button => {
      if (button.tagName === 'BUTTON' && button.title === 'Add comment') {
        button.addEventListener('click', this.showCommentForm.bind(this))
      }
    })
  }

  showCommentForm(event) {
    event.preventDefault()
    const button = event.currentTarget
    const lineCode = button.dataset.lineCode
    const lineType = button.dataset.lineType

    const lineRow = button.closest('.group.relative')

    this.hideAllCommentForms()

    this.insertCommentForm(lineRow, lineCode, lineType)

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
      <div class="border-t border-b border-gray-300 bg-gray-50 p-4 w-full" id="comment-form-${lineCode}" data-line-code="${lineCode}" data-line-type="${lineType}">
        <div class="mb-3">
          <span class="text-sm text-gray-600">
            Commenting on this line
          </span>
        </div>
        <div class="mb-4">
          <textarea placeholder="Add a comment..."
                   class="w-full p-3 border border-gray-300 rounded-md resize-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                   rows="4"
                   data-line-code="${lineCode}"></textarea>
        </div>
        <div class="flex items-center justify-between">
          <div class="text-xs text-gray-500">
            Markdown is supported
          </div>
          <div class="flex gap-2">
            <button type="button" class="px-3 py-1 text-sm text-gray-600 hover:text-gray-800 cancel-comment" data-line-code="${lineCode}">
              Cancel
            </button>
            <button type="button" class="px-4 py-2 bg-blue-600 text-white text-sm rounded-md hover:bg-blue-700 submit-comment" data-line-code="${lineCode}">
              Add to review
            </button>
          </div>
        </div>
      </div>
    `

    // Insert after the current line row (at same level as other diff rows)
    lineRow.insertAdjacentElement('afterend', formContainer)

    // Focus the textarea
    const textarea = formContainer.querySelector('textarea')
    textarea.focus()

    // Add event listeners
    formContainer.querySelector('.cancel-comment').addEventListener('click', () => {
      this.cancelComment(lineCode)
    })

    formContainer.querySelector('.submit-comment').addEventListener('click', () => {
      this.submitComment(lineCode)
    })
  }

  cancelComment(lineCode) {
    const form = this.element.querySelector(`#comment-form-${lineCode}`)
    if (form) {
      form.closest('.diff-comment-form-wrapper').remove()
    }

    // Show the comment button again
    const button = this.element.querySelector(`button[data-line-code="${lineCode}"]`)
    if (button) {
      button.style.opacity = ''
    }
  }

  async submitComment(lineCode) {
    const form = this.element.querySelector(`#comment-form-${lineCode}`)
    const textarea = form.querySelector('textarea')
    const content = textarea.value.trim()
    const lineType = form.dataset.lineType

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

      const position = this.buildPositionData(lineCode, lineType)

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
            line_code: lineCode,
            position: JSON.stringify(position)
          }
        })
      })

      const turboStreamContent = await response.text()
      Turbo.renderStreamMessage(turboStreamContent)
    } catch (error) {
      console.error('Error submitting comment:', error)
      alert('Failed to submit comment')
      submitButton.disabled = false
      submitButton.textContent = originalText
    }
  }

  buildPositionData(lineCode, lineType) {
    const parts = lineCode.split('_')
    if (parts.length < 3) return null

    const rawOldLine = parseInt(parts[1])
    const rawNewLine = parseInt(parts[2])

    const oldLine = lineType === 'addition' ? null : rawOldLine
    const newLine = lineType === 'deletion' ? null : rawNewLine

    const oldPath = this.element.dataset.oldPath
    const newPath = this.element.dataset.newPath

    const baseSha = this.element.dataset.baseSha
    const startSha = this.element.dataset.startSha
    const headSha = this.element.dataset.headSha

    return {
      base_sha: baseSha,
      start_sha: startSha,
      head_sha: headSha,
      old_path: oldPath,
      new_path: newPath,
      position_type: 'text',
      old_line: oldLine,
      new_line: newLine,
      line_range: {
        start: {
          line_code: lineCode,
          type: lineType === 'addition' ? 'new' : lineType === 'deletion' ? 'old' : null,
          old_line: oldLine,
          new_line: newLine
        },
        end: {
          line_code: lineCode,
          type: lineType === 'addition' ? 'new' : lineType === 'deletion' ? 'old' : null,
          old_line: oldLine,
          new_line: newLine
        }
      },
      ignore_whitespace_change: false
    }
  }

  hideAllCommentForms() {
    this.element.querySelectorAll('.diff-comment-form-wrapper').forEach(form => {
      form.remove()
    })
  }
}