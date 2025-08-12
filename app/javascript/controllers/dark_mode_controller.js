import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dark-mode"
export default class extends Controller {
  static targets = ["toggle", "icon"]

  connect() {
    // Check for saved theme preference or default to light mode
    const savedTheme = localStorage.getItem('theme')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (savedTheme) {
      this.setTheme(savedTheme)
    } else if (prefersDark) {
      this.setTheme('dark')
    } else {
      this.setTheme('light')
    }

    this.updateIcon()
  }

  toggle() {
    const currentTheme = document.documentElement.getAttribute('data-bs-theme')
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark'

    this.setTheme(newTheme)
    this.updateIcon()
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('theme', theme)
  }

  updateIcon() {
    const currentTheme = document.documentElement.getAttribute('data-bs-theme')
    const icon = this.iconTarget

    if (currentTheme === 'dark') {
      icon.className = 'bi bi-sun-fill'
      this.toggleTarget.title = 'Switch to light mode'
    } else {
      icon.className = 'bi bi-moon-fill'
      this.toggleTarget.title = 'Switch to dark mode'
    }
  }
}
