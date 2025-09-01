// app/javascript/controllers/driver_dashboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Driver dashboard connected")

    // Listen for turbo events
    document.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    document.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
    document.addEventListener("turbo:before-stream-render", this.handleBeforeStreamRender.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    document.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
    document.removeEventListener("turbo:before-stream-render", this.handleBeforeStreamRender.bind(this))
  }

  handleSubmitStart(event) {
    console.log("Form submission started:", event.target)

    // Show loading state
    const submitButton = event.target.querySelector('input[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
      submitButton.value = "Carregando..."
    }
  }

  handleSubmitEnd(event) {
    console.log("Form submission ended:", event.detail.success)

    // Reset button state
    const submitButton = event.target.querySelector('input[type="submit"]')
    if (submitButton) {
      submitButton.disabled = false
      // Reset original text (we'll need to store this)
    }
  }

  handleBeforeStreamRender(event) {
    console.log("Turbo stream about to render:", event.target)
  }
}
