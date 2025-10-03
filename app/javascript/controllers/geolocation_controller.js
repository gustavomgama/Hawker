import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="geolocation"
export default class extends Controller {
  connect() {
    console.log("Geolocation controller connected")
  }

  getCurrentLocation(event) {
    event.preventDefault()

    if (!navigator.geolocation) {
      this.showError("Geolocation is not supported by your browser")
      return
    }

    this.showStatus("Getting your location...")

    navigator.geolocation.getCurrentPosition(
      (position) => this.handleSuccess(position),
      (error) => this.handleError(error),
      { maximumAge: 0, enableHighAccuracy: true, timeout: 10000 }
    )
  }

  handleSuccess(position) {
    const lat = position.coords.latitude
    const long = position.coords.longitude

    if (this.hasLatTarget) this.latTarget.value = lat
    if (this.hasLongTarget) this.longTarget.value = long

    this.showStatus(`Location found: ${lat.toFixed(8)}, ${long.toFixed(8)}`)

    this.reverseGeocode(lat, long)
  }

  handleError(error) {
    let error = "Unable to get your location"

    switch(error.code) {
      case error.PERMISSION_DENIED:
        message = "Location permission denied"
        break
      case error.POSITION_UNAVAILABLE:
        message = "Location info unavailable"
        break
      case error.TIMEOUT:
        message = "Time out"
        break
    }

    this.showError(message)
  }

  showStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = "text-sm text-blue-600"
    }
  }

  showError(message) {
    if (this.hasStatusTaget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = "text-sm text-red-600"
    }
  }

  reverseGecode(lat, long) {
    if (this.hasAddressTarget) {
      this.addressTarget.value = `${lat.toFixed(8)}, ${long.toFixed(8)}`
    }
  }
}
