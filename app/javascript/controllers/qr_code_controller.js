import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "button"]
  static values = { url: String, loaded: Boolean }

  toggle() {
    if (this.containerTarget.classList.contains("d-none")) {
      if (!this.loadedValue) {
        this.load()
      }
      this.containerTarget.classList.remove("d-none")
      this.buttonTarget.innerHTML = '<i class="bi bi-eye-slash"></i> Hide QR'
    } else {
      this.containerTarget.classList.add("d-none")
      this.buttonTarget.innerHTML = '<i class="bi bi-qr-code"></i> Show QR'
    }
  }

  async load() {
    try {
      const response = await fetch(this.urlValue)
      const html = await response.text()
      this.containerTarget.querySelector(".qr-container").innerHTML = html
      this.loadedValue = true
    } catch (error) {
      this.containerTarget.querySelector(".qr-container").innerHTML = '<span class="text-danger">Failed to load QR code</span>'
    }
  }
}
