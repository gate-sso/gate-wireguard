import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  async copy(event) {
    const btn = event.currentTarget
    const text = btn.dataset.clipboardTextParam

    try {
      await navigator.clipboard.writeText(text)

      const originalHTML = btn.innerHTML
      btn.innerHTML = '<i class="bi bi-check"></i>'
      btn.classList.add('btn-success')
      btn.classList.remove('btn-outline-secondary')

      setTimeout(() => {
        btn.innerHTML = originalHTML
        btn.classList.remove('btn-success')
        btn.classList.add('btn-outline-secondary')
      }, 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }
}
