import { Controller } from "@hotwired/stimulus"

// Token-based issue search box: focusing the input offers filter types
// (Status/Label/Author/Assignee/Sort), picking one turns the input into a
// pending value editor scoped to that type, and selecting a value commits
// it as a removable pill. Free text typed without picking a type is a
// plain search term. Every change re-submits the underlying GET form.
export default class extends Controller {
  static targets = ["input", "dropdown", "box", "hiddenFields", "form", "dropdownItem"]
  static values = {
    statusOptions: Array,
    labelOptions: Array,
    authorOptions: Array,
    assigneeOptions: Array,
    reviewerOptions: Array,
    sortScopes: Array,
    initial: Object
  }

  connect() {
    this.types = [
      { key: 'status', label: 'Status' },
      { key: 'label', label: 'Label' },
      { key: 'author', label: 'Author' },
      { key: 'assignee', label: 'Assignee' },
    ]
    if (this.hasReviewerOptionsValue) this.types.push({ key: 'reviewer', label: 'Reviewer' })
    this.types.push({ key: 'sort', label: 'Sort' })

    this.sortOptions = [
      ...this.sortScopesValue.flatMap(scope => [
        { value: `${scope.toLowerCase()}_asc`, display: `${scope} ↑` },
        { value: `${scope.toLowerCase()}_desc`, display: `${scope} ↓` },
      ]),
      { value: 'created_at_asc', display: 'Created ↑' },
      { value: 'created_at_desc', display: 'Created ↓' },
      { value: 'updated_at_asc', display: 'Updated ↑' },
      { value: 'updated_at_desc', display: 'Updated ↓' },
    ]

    this.tokens = this.buildInitialTokens()
    this.pendingType = null

    if (this.initialValue.search) this.inputTarget.value = this.initialValue.search

    this.boundClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.boundClickOutside)

    this.render()
  }

  disconnect() {
    document.removeEventListener('click', this.boundClickOutside)
  }

  buildInitialTokens() {
    const tokens = []
    const init = this.initialValue

    if (init.status) tokens.push({ type: 'status', value: init.status, display: this.capitalize(init.status) })
    ;(init.label || []).forEach(l => tokens.push({ type: 'label', value: l, display: l }))
    if (init.author) tokens.push({ type: 'author', value: init.author, display: init.author })
    if (init.assignee) tokens.push({ type: 'assignee', value: init.assignee, display: init.assignee })
    if (init.reviewer) tokens.push({ type: 'reviewer', value: init.reviewer, display: init.reviewer })
    if (init.sort) {
      const opt = this.sortOptions.find(o => o.value === init.sort)
      tokens.push({ type: 'sort', value: init.sort, display: opt ? opt.display : init.sort })
    }

    return tokens
  }

  capitalize(s) {
    return s.charAt(0).toUpperCase() + s.slice(1)
  }

  optionsFor(type) {
    switch (type) {
      case 'status': return this.statusOptionsValue
      case 'label': return this.labelOptionsValue
      case 'author': return this.authorOptionsValue
      case 'assignee': return this.assigneeOptionsValue
      case 'reviewer': return this.reviewerOptionsValue
      default: return []
    }
  }

  open() {
    if (this.dropdownTarget.classList.contains('hidden')) this.openForCurrentState()
  }

  openForCurrentState() {
    if (this.pendingType) this.showValueMenu(this.inputTarget.value)
    else this.showTypeMenu()
  }

  showTypeMenu() {
    const items = this.types
      .filter(t => t.key === 'label' || !this.tokens.some(tok => tok.type === t.key))
      .map(t => ({ display: t.label, key: t.key }))

    this.renderDropdown(items, (item) => {
      this.pendingType = item.key
      this.inputTarget.value = ''
      this.inputTarget.focus()
      this.render()
      this.showValueMenu('')
    })
  }

  showValueMenu(query) {
    const q = query.toLowerCase()

    if (this.pendingType === 'sort') {
      const items = this.sortOptions.filter(o => o.display.toLowerCase().includes(q))
      this.renderDropdown(items, (item) => this.commitSingleValue('sort', item))
      return
    }

    let items = this.optionsFor(this.pendingType)
      .filter(v => v.toLowerCase().includes(q))
      .map(v => ({ display: v, value: v }))
    if (this.pendingType === 'label' && !q) items = items.slice(0, 10)

    this.renderDropdown(items, (item) => this.commitValue(item))
  }

  commitValue(item) {
    const type = this.pendingType
    this.tokens = this.tokens.filter(t => !(t.type === type && type !== 'label'))
    this.tokens.push({ type, value: item.value, display: item.display })
    this.pendingType = null
    this.inputTarget.value = ''
    this.render()
    this.submit()
    this.inputTarget.focus()
    this.showTypeMenu()
  }

  commitSingleValue(type, item) {
    this.tokens = this.tokens.filter(t => t.type !== type)
    this.tokens.push({ type, value: item.value, display: item.display })
    this.pendingType = null
    this.inputTarget.value = ''
    this.render()
    this.submit()
    this.inputTarget.focus()
    this.showTypeMenu()
  }

  renderDropdown(items, onPick) {
    this.dropdownTarget.innerHTML = ''

    if (!items.length) {
      this.dropdownTarget.innerHTML = '<div class="px-3 py-2 text-sm text-gray-400">No matches</div>'
    } else {
      items.forEach(item => {
        const div = document.createElement('div')
        div.className = 'px-3 py-2 text-sm cursor-pointer border-b border-slate-100 last:border-b-0 hover:bg-slate-50 flex items-center justify-between'
        div.setAttribute('data-search-token-target', 'dropdownItem')
        div.textContent = item.display
        div.addEventListener('click', (e) => {
          e.stopPropagation()
          onPick(item)
        })
        this.dropdownTarget.appendChild(div)
      })
    }

    this.dropdownTarget.classList.remove('hidden')
  }

  closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
  }

  onInput() {
    if (this.pendingType) {
      this.render()
      this.showValueMenu(this.inputTarget.value)
    }
  }

  onKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      if (this.pendingType) {
        const first = this.dropdownItemTargets[0]
        if (first && !this.dropdownTarget.classList.contains('hidden')) first.click()
      } else {
        this.closeDropdown()
        this.submit()
      }
    }

    if (event.key === 'Escape') {
      this.pendingType = null
      this.render()
      this.closeDropdown()
    }

    if (event.key === 'Backspace' && !this.inputTarget.value && !this.pendingType && this.tokens.length) {
      this.tokens.pop()
      this.render()
      this.submit()
    }
  }

  removeToken(event) {
    event.stopPropagation()
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.tokens.splice(index, 1)
    this.render()
    this.submit()
  }

  cancelPending(event) {
    event.stopPropagation()
    this.pendingType = null
    this.inputTarget.value = ''
    this.render()
    this.closeDropdown()
    this.inputTarget.focus()
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) this.closeDropdown()
  }

  render() {
    this.boxTarget.querySelectorAll('.search-token-pill').forEach(el => el.remove())

    this.tokens.forEach((token, index) => {
      const pill = this.buildPill({
        labelText: this.labelFor(token.type),
        valueText: token.display,
        pending: false,
        removeAction: 'removeToken',
        index
      })
      this.boxTarget.insertBefore(pill, this.inputTarget)
    })

    if (this.pendingType) {
      const pill = this.buildPill({
        labelText: this.labelFor(this.pendingType),
        valueText: this.inputTarget.value || '|',
        pending: true,
        removeAction: 'cancelPending'
      })
      this.boxTarget.insertBefore(pill, this.inputTarget)
    }

    this.syncHiddenFields()
  }

  buildPill({ labelText, valueText, pending, removeAction, index }) {
    const el = document.createElement('span')
    el.className = pending
      ? 'search-token-pill inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium bg-amber-50 text-amber-700 border border-amber-200'
      : 'search-token-pill inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium bg-blue-50 text-blue-600 border border-blue-100'

    const label = document.createElement('b')
    label.className = 'font-semibold'
    label.textContent = `${labelText}:`
    el.appendChild(label)
    el.appendChild(document.createTextNode(` ${valueText} `))

    const remove = document.createElement('span')
    remove.className = pending
      ? 'cursor-pointer text-amber-700 hover:text-red-600 font-bold'
      : 'cursor-pointer text-blue-600 hover:text-red-600 font-bold'
    remove.textContent = '×'
    remove.setAttribute('data-action', `click->search-token#${removeAction}`)
    if (index !== undefined) remove.setAttribute('data-index', index)
    el.appendChild(remove)

    return el
  }

  labelFor(key) {
    return this.types.find(t => t.key === key).label
  }

  syncHiddenFields() {
    this.hiddenFieldsTarget.innerHTML = ''

    const add = (name, value) => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = name
      input.value = value
      this.hiddenFieldsTarget.appendChild(input)
    }

    const status = this.tokens.find(t => t.type === 'status')
    if (status) add('status', status.value.toLowerCase())

    this.tokens.filter(t => t.type === 'label').forEach(t => add('label[]', t.value))

    const author = this.tokens.find(t => t.type === 'author')
    if (author) add('author', author.value)

    const assignee = this.tokens.find(t => t.type === 'assignee')
    if (assignee) add('assignee', assignee.value)

    const reviewer = this.tokens.find(t => t.type === 'reviewer')
    if (reviewer) add('reviewer', reviewer.value)

    const sort = this.tokens.find(t => t.type === 'sort')
    if (sort) add('sort', sort.value)

    if (!this.pendingType && this.inputTarget.value.trim()) add('search', this.inputTarget.value.trim())
  }

  submit() {
    this.syncHiddenFields()
    this.formTarget.requestSubmit()
  }
}
