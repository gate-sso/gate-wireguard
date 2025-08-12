import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="network-address"
export default class extends Controller {
  static targets = ["networkRange", "serverIp"]

  connect() {
    console.log("Network address controller connected")
  }

  // Calculate the last usable IP address in a network range
  calculateServerIp() {
    const networkRange = this.networkRangeTarget.value.trim()

    if (!networkRange) {
      this.serverIpTarget.value = ""
      return
    }

    try {
      let networkAddr, cidr

      // Check if CIDR notation is provided, default to /24 if not
      if (networkRange.includes('/')) {
        [networkAddr, cidr] = networkRange.split('/')
      } else {
        networkAddr = networkRange
        cidr = '24' // Default to /24
      }

      if (!networkAddr) {
        this.serverIpTarget.value = ""
        return
      }

      const cidrNumber = parseInt(cidr, 10)
      if (isNaN(cidrNumber) || cidrNumber < 0 || cidrNumber > 32) {
        this.serverIpTarget.value = ""
        return
      }

      // Parse the network address
      const octets = networkAddr.split('.').map(octet => parseInt(octet, 10))
      if (octets.length !== 4 || octets.some(octet => isNaN(octet) || octet < 0 || octet > 255)) {
        this.serverIpTarget.value = ""
        return
      }

      // Calculate network and broadcast addresses
      const hostBits = 32 - cidrNumber
      const numHosts = Math.pow(2, hostBits)

      // Convert IP to 32-bit integer
      let networkInt = (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + octets[3]

      // Mask to get network address
      const mask = (0xFFFFFFFF << hostBits) >>> 0
      networkInt = (networkInt & mask) >>> 0

      // Convert network address back to dotted decimal for auto-correction
      const correctedNetworkOctets = [
        (networkInt >>> 24) & 0xFF,
        (networkInt >>> 16) & 0xFF,
        (networkInt >>> 8) & 0xFF,
        networkInt & 0xFF
      ]

      const correctedNetworkAddr = correctedNetworkOctets.join('.')

      // Auto-correct the input field to show proper network address
      if (cidr === '24') {
        this.networkRangeTarget.value = correctedNetworkAddr
      } else {
        this.networkRangeTarget.value = `${correctedNetworkAddr}/${cidr}`
      }

      // Calculate the last usable IP (broadcast - 1)
      // For /24: last usable is .254, for /30: last usable is .2, etc.
      let lastUsableInt
      if (hostBits <= 1) {
        // For /31 and /32, use the network address itself
        lastUsableInt = networkInt
      } else {
        // For other networks, last usable is broadcast - 1
        const broadcastInt = (networkInt + numHosts - 1) >>> 0
        lastUsableInt = (broadcastInt - 1) >>> 0
      }

      // Convert back to dotted decimal
      const lastUsableOctets = [
        (lastUsableInt >>> 24) & 0xFF,
        (lastUsableInt >>> 16) & 0xFF,
        (lastUsableInt >>> 8) & 0xFF,
        lastUsableInt & 0xFF
      ]

      const serverIp = lastUsableOctets.join('.')
      this.serverIpTarget.value = serverIp

    } catch (error) {
      console.error("Error calculating server IP:", error)
      this.serverIpTarget.value = ""
    }
  }
}
