import { Controller } from "@hotwired/stimulus"

// Manages dynamic add/remove of served network CIDR inputs
// and handles visibility based on infrastructure node toggle.
// Connects to data-controller="served-networks"
export default class extends Controller {
  static targets = ["list", "hidden", "template", "container", "nodeCheckbox"]

  connect() {
    this.toggle()
  }

  // Toggles visibility of the served networks section based on checkbox state
  toggle() {
    if (!this.hasNodeCheckboxTarget || !this.hasContainerTarget) return

    if (this.nodeCheckboxTarget.checked) {
      this.containerTarget.classList.remove("d-none")
    } else {
      this.containerTarget.classList.add("d-none")
    }
  }

  // Adds a new CIDR input row using the template
  add(event) {
    event.preventDefault()
    if (!this.hasTemplateTarget) return

    const content = this.templateTarget.innerHTML
    this.listTarget.insertAdjacentHTML("beforeend", content)
  }

  // Removes a CIDR input row
  remove(event) {
    event.preventDefault()
    event.target.closest(".input-group").remove()
    this.sync()
  }

  // Joins all individual inputs into the comma-separated hidden field
  sync() {
    const entries = this.listTarget.querySelectorAll("[data-served-networks-target='entry']")
    const values = Array.from(entries)
      .map(input => input.value.trim())
      .filter(v => v.length > 0)
    this.hiddenTarget.value = values.join(", ")
  }
}
