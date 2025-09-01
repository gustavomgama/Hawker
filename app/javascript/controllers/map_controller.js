// app/javascript/controllers/customer_map_controller.js
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  connect() {
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    // Poll driver status every 15 seconds as fallback
    this.pollingInterval = setInterval(() => {
      this.checkDriverStatus()
    }, 15000)
  }

  stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
    }
  }

  async checkDriverStatus() {
    try {
      const response = await fetch('/driver_status')
      const driverState = await response.json()

      // Simple DOM updates if needed
      // Most updates handled by Turbo Streams
    } catch (error) {
      console.log('Polling error:', error)
    }
  }
}
