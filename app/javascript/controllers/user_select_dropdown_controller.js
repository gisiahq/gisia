import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "options", "form", "searchForm", "queryInput", "selectedUsers", "searchInput"]
  static values = { url: String, fieldType: String, resourceId: String, resourceType: String, selected: String }

  connect() {
    this.selectedUsers = new Set()
    this.searchTimeout = null
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)

    this.loadSelectedUsers()
  }

  loadSelectedUsers() {
    if (!this.selectedUsers) {
      this.selectedUsers = new Set()
    }

    this.selectedUsers.clear()

    if (this.selectedValue) {
      const selectedIds = this.selectedValue.split(',').filter(id => id.trim() !== '')
      selectedIds.forEach(id => this.selectedUsers.add(id))
    }
  }

  selectedValueChanged() {
    this.loadSelectedUsers()
    this.syncSelectedUsers()
  }

  syncSelectedUsers() {
    if (!this.selectedUsers) return

    const selectedIds = Array.from(this.selectedUsers)

    this.selectedUsersTargets.forEach(target => {
      target.dataset.selectedIds = selectedIds.join(',')

      target.dispatchEvent(new CustomEvent('selectedUsersChanged', {
        detail: { selectedIds, fieldType: this.fieldTypeValue }
      }))
    })

    if (this.hasSearchInputTarget && this.searchInputTarget.value.trim()) {
      this.submitSearchForm(this.searchInputTarget.value.trim())
    }
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

  async toggleDropdown() {
    if (this.dropdownTarget.classList.contains('hidden')) {
      this.showDropdown()
      document.addEventListener('click', this.boundHandleClickOutside)
    } else {
      this.hideDropdown()
    }
  }

  async search(event) {
    const query = event.target.value.trim()

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    this.searchTimeout = setTimeout(async () => {
      if (query.length >= 1) {
        this.submitSearchForm(query)
      }
    }, 300)
  }

  submitSearchForm(query) {
    this.queryInputTarget.value = query

    const selectedIdsInput = this.searchFormTarget.querySelector('input[name="selected_ids"]')
    if (selectedIdsInput && this.selectedUsers) {
      selectedIdsInput.value = Array.from(this.selectedUsers).join(',')
    }

    this.searchFormTarget.requestSubmit()
  }

  selectUser(event) {
    event.stopPropagation()

    const userId = event.currentTarget.dataset.userId

    if (this.selectedUsers.has(userId)) {
      this.selectedUsers.delete(userId)
    } else {
      this.selectedUsers.add(userId)
    }

    this.syncSelectedUsers()
    this.updateFormAndSubmit()
    this.hideDropdown()
  }

  removeUser(event) {
    const userId = event.currentTarget.dataset.userId

    if (this.selectedUsers) {
      this.selectedUsers.delete(userId)
      this.selectedValue = Array.from(this.selectedUsers).join(',')
    }
  }

  updateFormAndSubmit() {
    const userIds = Array.from(this.selectedUsers)
    const form = this.formTarget
    const fieldName = `${this.resourceTypeValue}[${this.fieldTypeValue.slice(0, -1)}_ids][]`

    const existingInputs = form.querySelectorAll(`input[name="${fieldName}"]`)
    existingInputs.forEach(input => input.remove())

    if (userIds.length === 0) {
      const emptyInput = document.createElement('input')
      emptyInput.type = 'hidden'
      emptyInput.name = fieldName
      emptyInput.value = ''
      form.appendChild(emptyInput)
    } else {
      userIds.forEach(userId => {
        const userInput = document.createElement('input')
        userInput.type = 'hidden'
        userInput.name = fieldName
        userInput.value = userId
        userInput.setAttribute('data-user-id', userId)
        form.appendChild(userInput)
      })
    }

    form.requestSubmit()

    setTimeout(() => {
      this.selectedValue = userIds.join(',')
    }, 100)
  }

  showDropdown() {
    this.dropdownTarget.classList.remove('hidden')
    if (this.hasSearchInputTarget) {
      setTimeout(() => this.searchInputTarget.focus(), 0)
    }
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
    document.removeEventListener('click', this.boundHandleClickOutside)

    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
    }

    if (this.hasOptionsTarget) {
      const frameId = `user-dropdown-options-${this.fieldTypeValue}`

      this.optionsTarget.innerHTML = ''

      const frameDiv = document.createElement('div')
      frameDiv.id = frameId

      const messageDiv = document.createElement('div')
      messageDiv.className = 'px-3 py-2 text-slate-500 text-sm'
      messageDiv.textContent = 'Type to search users...'

      frameDiv.appendChild(messageDiv)
      this.optionsTarget.appendChild(frameDiv)
    }
  }
}