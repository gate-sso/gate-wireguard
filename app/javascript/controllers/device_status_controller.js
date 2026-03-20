import { Controller } from "@hotwired/stimulus"

// Polls /admin/device_status for live WireGuard peer status
// Updates online/offline dots, last seen, and transfer stats
// Connects to data-controller="device-status"
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 30000 } }

  connect() {
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue)
      if (!response.ok) return
      const devices = await response.json()
      this.update(devices)
    } catch (e) {
      // silently ignore polling errors
    }
  }

  update(devices) {
    // Update online counter
    const onlineCount = devices.filter(d => d.online).length
    const counter = document.getElementById("online-count")
    if (counter) counter.textContent = onlineCount

    // Update per-device status
    devices.forEach(device => {
      const row = document.querySelector(`[data-device-id="${device.id}"]`)
      if (!row) return

      // Status dot
      const dot = row.querySelector(".status-dot")
      if (dot) {
        dot.className = `status-dot ${device.online ? "online" : "offline"}`
        dot.title = device.online ? "Online" : "Offline"
      }

      // Last seen
      const lastSeen = row.querySelector(".last-seen")
      if (lastSeen) {
        lastSeen.textContent = device.last_handshake_ago || "never"
      }

      // Transfer
      const transfer = row.querySelector(".transfer")
      if (transfer) {
        transfer.textContent = `${this.formatBytes(device.rx_bytes)} / ${this.formatBytes(device.tx_bytes)}`
      }

      // Endpoint
      const endpoint = row.querySelector(".endpoint")
      if (endpoint) {
        endpoint.textContent = device.endpoint || "-"
      }

      // Dual Sparkline (rx in neon blue, tx in neon green)
      const sparkline = row.querySelector(".sparkline")
      if (sparkline) {
        this.updateDualSparkline(sparkline, device.rx_bytes, device.tx_bytes)
      }
    })
  }

  updateDualSparkline(el, rxBytes, txBytes) {
    // Store histories as data attributes
    let rxHistory = JSON.parse(el.dataset.rxHistory || "[]")
    let txHistory = JSON.parse(el.dataset.txHistory || "[]")

    rxHistory.push(rxBytes)
    txHistory.push(txBytes)

    // Keep last 40 samples for better visibility in small graph
    if (rxHistory.length > 40) rxHistory = rxHistory.slice(-40)
    if (txHistory.length > 40) txHistory = txHistory.slice(-40)

    el.dataset.rxHistory = JSON.stringify(rxHistory)
    el.dataset.txHistory = JSON.stringify(txHistory)

    if (rxHistory.length < 2) return

    // Compute rates (delta between samples)
    const rxRates = this.computeRates(rxHistory)
    const txRates = this.computeRates(txHistory)

    // Draw SVG
    const width = 100
    const height = 24
    const max = Math.max(...rxRates, ...txRates, 1024) // min 1KB scale
    const step = width / Math.max(rxRates.length - 1, 1)

    const rxPoints = this.generatePoints(rxRates, max, width, height, step)
    const txPoints = this.generatePoints(txRates, max, width, height, step)

    // Neon Blue for RX (Download), Neon Green for TX (Upload)
    el.innerHTML = `
      <svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" style="overflow: visible;">
        <polyline points="${rxPoints}" fill="none" stroke="#00d2ff" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="filter: drop-shadow(0 0 2px rgba(0,210,255,0.5));"/>
        <polyline points="${txPoints}" fill="none" stroke="#39ff14" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="filter: drop-shadow(0 0 2px rgba(57,255,20,0.5));"/>
      </svg>
    `
  }

  computeRates(history) {
    const rates = []
    for (let i = 1; i < history.length; i++) {
      rates.push(Math.max(0, history[i] - history[i - 1]))
    }
    return rates
  }

  generatePoints(rates, max, width, height, step) {
    return rates.map((v, i) => {
      const x = i * step
      const y = height - (v / max) * height
      return `${x},${y}`
    }).join(" ")
  }

  formatBytes(bytes) {
    if (bytes === 0) return "0 B"
    const units = ["B", "KB", "MB", "GB", "TB"]
    const i = Math.floor(Math.log(bytes) / Math.log(1024))
    return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`
  }
}
