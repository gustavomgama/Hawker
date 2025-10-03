import { Controller } from "@hotwired/stimulus"
import { createCustomer } from "@hotwired/turbo"

// Connects to data-controller="customer"
export default class extends Controller {
  static values = {
    requestId: String
  }

  connect() {
    this.subscription = createCustomer().subscriptions.create(
      {
        channel: "CustomerChannel",
        request_id: this.requestIdValue
      },
      {
        connected: () => {
          console.log("Connected to 'customer channel'")
        },

        disconnected: () => {
          console.log("Disconnected from 'customer channel'")
        },

        received: (data) => {
          console.log("Customer update:", data)
        }
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }
}
