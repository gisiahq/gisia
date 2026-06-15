import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "options", "form", "searchForm", "queryInput", "parentIdInput", "selectedIdInput", "searchInput"]
  static values = { url: String }

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
    if (this.hasSelectedIdInputTarget) {
      this.selectedIdInputTarget.value = this.parentIdInputTarget.value
    }
    this.searchFormTarget.requestSubmit()
  }

  selectEpic(event) {
    event.stopPropagation()

    const epicId = event.currentTarget.dataset.epicId
    const isSelected = event.currentTarget.dataset.selected === 'true'

    if (isSelected) {
      this.hideDropdown()
      return
    }

    this.parentIdInputTarget.value = epicId
    this.formTarget.requestSubmit()
    this.clearSearchInput()
    this.hideDropdown()
  }

  clearParent(event) {
    event.stopPropagation()

    this.parentIdInputTarget.value = ''
    this.formTarget.requestSubmit()
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
      this.optionsTarget.innerHTML = ''

      const frameDiv = document.createElement('div')
      frameDiv.id = 'epic-dropdown-options'

      const messageDiv = document.createElement('div')
      messageDiv.className = 'px-3 py-2 text-slate-500 text-sm'
      messageDiv.textContent = 'Type to search epics...'

      frameDiv.appendChild(messageDiv)
      this.optionsTarget.appendChild(frameDiv)
    }
  }
}
