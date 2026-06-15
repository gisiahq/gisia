import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "options", "form", "searchForm", "queryInput", "unlinkForm", "unlinkLabelId", "labelIdInput", "searchInput"]
  static values = { url: String, unlinkUrl: String, resourceId: String, resourceType: String }

  connect() {
    this.searchTimeout = null
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleClickOutside)
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  toggleDropdown() {
    if (this.dropdownTarget.classList.contains('hidden')) {
      this.showDropdown()
      document.addEventListener('click', this.boundHandleClickOutside)
    } else {
      this.hideDropdown()
    }
  }

  search(event) {
    const query = event.target.value.trim()

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    this.searchTimeout = setTimeout(() => {
      if (query.length >= 1) {
        this.submitSearchForm(query)
      }
    }, 300)
  }

  submitSearchForm(query) {
    this.queryInputTarget.value = query
    this.searchFormTarget.requestSubmit()
  }

  selectLabel(event) {
    event.stopPropagation()

    const labelId = event.currentTarget.dataset.labelId
    const isSelected = event.currentTarget.dataset.selected === 'true'

    if (isSelected) {
      this.hideDropdown()
      return
    }

    this.linkLabel(labelId)
  }

  linkLabel(labelId) {
    this.labelIdInputTarget.value = labelId
    this.formTarget.requestSubmit()
    this.clearSearchInput()
    this.hideDropdown()
  }

  unlinkLabel(labelId) {
    this.unlinkLabelIdTarget.value = labelId
    this.unlinkFormTarget.requestSubmit()
    this.clearSearchInput()
    this.hideDropdown()
  }

  removeLabel(event) {
    event.stopPropagation()
    this.unlinkLabel(event.currentTarget.dataset.labelId)
  }

  showDropdown() {
    this.dropdownTarget.classList.remove('hidden')
    if (this.hasSearchInputTarget) {
      setTimeout(() => this.searchInputTarget.focus(), 0)
    }
  }

  clearSearchInput() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
    }
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
    document.removeEventListener('click', this.boundHandleClickOutside)
    this.clearSearchInput()

    if (this.hasOptionsTarget) {
      const frameId = "label-dropdown-options"

      this.optionsTarget.innerHTML = ''

      const frameDiv = document.createElement('div')
      frameDiv.id = frameId

      const messageDiv = document.createElement('div')
      messageDiv.className = 'px-3 py-2 text-slate-500 text-sm'
      messageDiv.textContent = 'Type to search labels...'

      frameDiv.appendChild(messageDiv)
      this.optionsTarget.appendChild(frameDiv)
    }
  }
}
