import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "name"]

  updateName() {
    const selectedOption = this.selectTarget.selectedOptions[0]
    const name = selectedOption?.dataset?.name || ""
    this.nameTarget.value = name
  }
}
