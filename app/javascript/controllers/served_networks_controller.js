import { Controller } from "@hotwired/stimulus"

// Manages dynamic add/remove of served network CIDR inputs
// Connects to data-controller="served-networks"
export default class extends Controller {
  static targets = ["list", "hidden", "template"]

  add(event) {
    event.preventDefault()
    const entry = document.createElement("div")
    entry.className = "input-group input-group-sm mb-2"
    entry.innerHTML = `
      <span class="input-group-text font-mono" style="font-size: 0.75rem;">CIDR</span>
      <input type="text" class="form-control font-mono" placeholder="192.168.1.0/24"
             data-served-networks-target="entry" data-action="input->served-networks#sync">
      <button type="button" class="btn btn-outline-danger" data-action="click->served-networks#remove">
        <i class="bi bi-x-lg"></i>
      </button>
    `
    this.listTarget.appendChild(entry)
  }

  remove(event) {
    event.preventDefault()
    event.target.closest(".input-group").remove()
    this.sync()
  }

  sync() {
    const entries = this.listTarget.querySelectorAll("[data-served-networks-target='entry']")
    const values = Array.from(entries)
      .map(input => input.value.trim())
      .filter(v => v.length > 0)
    this.hiddenTarget.value = values.join(", ")
  }
}
