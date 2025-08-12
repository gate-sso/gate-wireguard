import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fqdn", "publicIp"]

  connect() {
    console.log("FQDN resolver controller connected")
    this.debounceTimeout = null
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  async resolveFqdn() {
    // Clear any existing timeout
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }

    // Debounce the DNS resolution (wait 1 second after user stops typing)
    this.debounceTimeout = setTimeout(() => {
      this.performDnsResolution()
    }, 1000)
  }

  async performDnsResolution() {
    const fqdn = this.fqdnTarget.value.trim()

    if (!fqdn) {
      this.publicIpTarget.value = ""
      this.clearMessages()
      return
    }

    // Basic FQDN validation
    if (!this.isValidFqdn(fqdn)) {
      this.showError("Please enter a valid FQDN (e.g., vpn.example.com)")
      return
    }

    try {
      this.showLoading()
      const ipAddress = await this.lookupDns(fqdn)

      if (ipAddress) {
        this.publicIpTarget.value = ipAddress
        this.showSuccess(`Resolved ${fqdn} to ${ipAddress}`)
      } else {
        this.showError(`Could not resolve ${fqdn}`)
        this.publicIpTarget.value = ""
      }
    } catch (error) {
      console.error("DNS resolution error:", error)
      this.showError(`Failed to resolve ${fqdn}: ${error.message}`)
      this.publicIpTarget.value = ""
    }
  }

  async lookupDns(fqdn) {
    // Use a public DNS over HTTPS service for resolution
    // We'll use Cloudflare's DNS over HTTPS API
    const dohUrl = `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(fqdn)}&type=A`

    try {
      const response = await fetch(dohUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/dns-json',
        }
      })

      if (!response.ok) {
        throw new Error(`DNS lookup failed: ${response.status}`)
      }

      const data = await response.json()

      // Check if we got any A records
      if (data.Answer && data.Answer.length > 0) {
        // Find the first A record (IPv4)
        const aRecord = data.Answer.find(record => record.type === 1) // Type 1 = A record
        if (aRecord) {
          return aRecord.data
        }
      }

      return null
    } catch (error) {
      console.error("DNS over HTTPS lookup failed:", error)
      throw error
    }
  }

  isValidFqdn(fqdn) {
    // Basic FQDN validation regex
    const fqdnRegex = /^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/
    return fqdnRegex.test(fqdn)
  }

  showLoading() {
    this.publicIpTarget.value = "Resolving..."
    this.publicIpTarget.disabled = true
  }

  showSuccess(message) {
    this.publicIpTarget.disabled = false
    this.clearMessages()
    this.showMessage(message, "success")
  }

  showError(message) {
    this.publicIpTarget.disabled = false
    this.clearMessages()
    this.showMessage(message, "error")
  }

  showMessage(message, type) {
    // Remove any existing message
    this.clearMessages()

    // Create message element
    const messageDiv = document.createElement("div")
    messageDiv.className = `alert alert-${type === "error" ? "danger" : "success"} mt-2 fqdn-resolver-message`
    messageDiv.textContent = message

    // Add message after the FQDN input
    this.fqdnTarget.parentNode.appendChild(messageDiv)

    // Auto-remove success messages after 3 seconds
    if (type === "success") {
      setTimeout(() => this.clearMessages(), 3000)
    }
  }

  clearMessages() {
    const existingMessages = document.querySelectorAll(".fqdn-resolver-message")
    existingMessages.forEach(msg => msg.remove())
  }
}
