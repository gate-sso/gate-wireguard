import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["forwardInterface", "privateAddress"]

    connect() {
        console.log("Network interface controller connected")
        this.populateInterfaceInfo()
    }

    async populateInterfaceInfo() {
        try {
            console.log("Fetching network interface information...")
            const response = await fetch('/admin/network_interface_info', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`)
            }

            const data = await response.json()
            console.log("Network interface data received:", data)

            if (data.default_gateway && data.default_gateway.success) {
                this.populateDefaultGateway(data.default_gateway)
            } else {
                this.showFallbackOptions(data.all_interfaces)
            }

        } catch (error) {
            console.error("Error fetching network interface info:", error)
            this.showError("Could not auto-detect network interface. Please enter manually.")
        }
    }

    populateDefaultGateway(gatewayInfo) {
        const { interface_name, ip_address } = gatewayInfo

        // Only populate if fields are empty
        if (this.forwardInterfaceTarget.value.trim() === "") {
            this.forwardInterfaceTarget.value = interface_name
            this.showSuccess(`Auto-detected forward interface: ${interface_name}`)
        }

        if (this.privateAddressTarget.value.trim() === "") {
            this.privateAddressTarget.value = ip_address
            this.showSuccess(`Auto-detected private IP address: ${ip_address}`)
        }

        console.log(`Auto-populated: Interface=${interface_name}, IP=${ip_address}`)
    }

    showFallbackOptions(allInterfacesData) {
        if (!allInterfacesData || !allInterfacesData.success) {
            this.showError("Could not detect network interfaces")
            return
        }

        const interfaces = allInterfacesData.interfaces
        if (interfaces && interfaces.length > 0) {
            // Use the first non-loopback interface as fallback
            const fallbackInterface = interfaces.find(iface =>
                iface.name !== 'lo' &&
                !iface.ip.startsWith('127.') &&
                !iface.ip.startsWith('169.254.') // Skip link-local
            ) || interfaces[0]

            if (fallbackInterface) {
                this.populateDefaultGateway({
                    interface_name: fallbackInterface.name,
                    ip_address: fallbackInterface.ip
                })
                this.showInfo(`Using fallback interface: ${fallbackInterface.name} (${fallbackInterface.ip})`)
            }
        } else {
            this.showError("No network interfaces detected")
        }
    }

    showSuccess(message) {
        this.showMessage(message, "success")
    }

    showInfo(message) {
        this.showMessage(message, "info")
    }

    showError(message) {
        this.showMessage(message, "error")
    }

    showMessage(message, type) {
        // Remove any existing messages
        this.clearMessages()

        // Create message element
        const messageDiv = document.createElement("div")
        const alertClass = type === "error" ? "alert-danger" :
            type === "info" ? "alert-info" : "alert-success"
        messageDiv.className = `alert ${alertClass} mt-2 network-interface-message`
        messageDiv.innerHTML = `
      <div class="d-flex align-items-center">
        <strong>${type === "error" ? "⚠️" : type === "info" ? "ℹ️" : "✅"}</strong>
        <span class="ml-2">${message}</span>
      </div>
    `

        // Add message after the forward interface field
        this.forwardInterfaceTarget.parentNode.appendChild(messageDiv)

        // Auto-remove non-error messages after 5 seconds
        if (type !== "error") {
            setTimeout(() => this.clearMessages(), 5000)
        }
    }

    clearMessages() {
        const existingMessages = document.querySelectorAll(".network-interface-message")
        existingMessages.forEach(msg => msg.remove())
    }

    refreshInterfaceInfo() {
        this.clearMessages()
        this.showInfo("Refreshing network interface information...")
        this.populateInterfaceInfo()
    }
}
