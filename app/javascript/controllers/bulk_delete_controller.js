import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "deleteButton", "count"]

  connect() {
    this.updateButton()
  }

  toggle() {
    this.updateButton()
  }

  updateButton() {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (checkedCount > 0) {
      this.deleteButtonTarget.classList.remove("hidden")
      this.countTarget.textContent = checkedCount
    } else {
      this.deleteButtonTarget.classList.add("hidden")
    }
  }

  confirmDelete(event) {
    const count = this.checkboxTargets.filter(cb => cb.checked).length
    const message = `Are you sure you want to delete ${count} board(s)? This cannot be undone.`

    if (!confirm(message)) {
      event.preventDefault()
    }
  }
}
