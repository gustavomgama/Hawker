import { Controller } from "@hotwired/stimulus"
import { createCustomer } from "hotwired/turbo"

// Connects to data-controller="driver"
export default class extends Controller {
  connect() {
    this.subscription = createCustomer().subscriptions.create(
      {
        channel: "DriverChannel"
      },
      {
        connected: () => {
          console.log("Connected to 'driver channel'")
        },

        disconnected: () => {
          console.log("Disconnceted from 'driver channel'")
        },

        received: (data) => {
          console.log("Driver update", data)

          if (data.type === "new_request") {
            this.playNotificationSound
          }
        }
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  playNotificationSound() {
    const audio = new Audio("public/notification.mp3")
    audio.play().catch(e => console.log("Could not play sound:", e))
  }
}
