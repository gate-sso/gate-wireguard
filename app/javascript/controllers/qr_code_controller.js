import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, loaded: Boolean }

  open() {
    let modal = document.getElementById("qr-modal")
    if (!modal) {
      document.body.insertAdjacentHTML("beforeend", `
        <div class="modal fade" id="qr-modal" tabindex="-1">
          <div class="modal-dialog modal-dialog-centered modal-sm">
            <div class="modal-content">
              <div class="modal-header">
                <h6 class="modal-title">Scan with WireGuard app</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
              </div>
              <div class="modal-body text-center">
                <div class="qr-container" id="qr-modal-body">
                  <div class="spinner-border spinner-border-sm text-secondary" role="status">
                    <span class="visually-hidden">Loading...</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      `)
      modal = document.getElementById("qr-modal")
    }

    const body = document.getElementById("qr-modal-body")
    body.innerHTML = '<div class="spinner-border spinner-border-sm text-secondary" role="status"><span class="visually-hidden">Loading...</span></div>'

    const bsModal = new bootstrap.Modal(modal)
    bsModal.show()

    this.loadQR(body)
  }

  async loadQR(container) {
    try {
      const response = await fetch(this.urlValue)
      const html = await response.text()
      container.innerHTML = html
    } catch {
      container.innerHTML = '<span class="text-danger">Failed to load QR code</span>'
    }
  }
}
