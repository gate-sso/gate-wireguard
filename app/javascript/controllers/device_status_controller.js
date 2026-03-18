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

      // Sparkline (rx + tx combined, appended as new data point)
      const sparkline = row.querySelector(".sparkline")
      if (sparkline) {
        this.updateSparkline(sparkline, device.rx_bytes + device.tx_bytes)
      }
    })
  }

  updateSparkline(el, totalBytes) {
    // Store history as data attribute (JSON array of values)
    let history = JSON.parse(el.dataset.history || "[]")
    history.push(totalBytes)
    // Keep last 60 samples (at 30s interval = 30 minutes of data)
    if (history.length > 60) history = history.slice(-60)
    el.dataset.history = JSON.stringify(history)

    // Compute deltas (rate of change between samples)
    if (history.length < 2) return
    const deltas = []
    for (let i = 1; i < history.length; i++) {
      deltas.push(Math.max(0, history[i] - history[i - 1]))
    }

    // Draw SVG sparkline
    const max = Math.max(...deltas, 1)
    const width = 80
    const height = 20
    const step = width / Math.max(deltas.length - 1, 1)

    const points = deltas.map((v, i) => {
      const x = i * step
      const y = height - (v / max) * height
      return `${x},${y}`
    }).join(" ")

    el.innerHTML = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
      <polyline points="${points}" fill="none" stroke="var(--color-accent, #10b981)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`
  }

  formatBytes(bytes) {
    if (bytes === 0) return "0 B"
    const units = ["B", "KB", "MB", "GB", "TB"]
    const i = Math.floor(Math.log(bytes) / Math.log(1024))
    return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`
  }
}
