import { Controller } from "@hotwired/stimulus"
import { OpenStreetMapProvider } from "leaflet-geosearch"
import tzlookup from "tz-lookup"

export default class extends Controller {
  static targets = ["input", "dropdown", "name", "latitude", "longitude", "zipcode", "timezone", "submit", "alert", "spinner"]

  connect() {
    this.provider = new OpenStreetMapProvider({
      params: { addressdetails: 1, format: "json" },
    })

    this.inputTarget.addEventListener("input", (e) => {
      clearTimeout(this.debounceTimer)
      this.#clearFields()

      const query = e.target.value
      if (query.length < 3) {
        this.#hideDropdown()
        return
      }

      this.debounceTimer = setTimeout(() => this.#search(query), 400)
    })

    this.element.addEventListener("turbo:submit-end", (e) => {
        this.spinnerTarget.classList.add("hidden")
        this.submitTarget.disabled = false

        if (!e.detail.success) return
        if (!this.#placeSelected()) return

        const timezone = this.element.querySelector("[name='timezone']")?.value || "UTC"

        this.dispatch("locationSelected", {
        detail: {
            name:      this.nameTarget.value,
            latitude:  this.latitudeTarget.value,
            longitude: this.longitudeTarget.value,
            zipcode:   this.zipcodeTarget.value,
            timezone: this.timezoneTarget.value,
        },
        bubbles: true
        })
    })

    document.addEventListener("click", this.#onOutsideClick)
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
    document.removeEventListener("click", this.#onOutsideClick)
  }

  submit(event) {
    if (!this.#placeSelected()) {
      event.preventDefault()
      this.alertTarget.classList.remove("hidden")
      return
    }
    this.spinnerTarget.classList.remove("hidden")
    this.submitTarget.disabled = true
  }


  async #search(query) {
    this.spinnerTarget.classList.remove("hidden")
    const results = await this.provider.search({ query })
    this.spinnerTarget.classList.add("hidden")
    this.#renderDropdown(results)
  }

  #renderDropdown(results) {
    this.dropdownTarget.innerHTML = ""

    if (!results.length) {
      this.#hideDropdown()
      return
    }

    results.forEach((result) => {
      const item = document.createElement("div")
      item.textContent = result.label
      item.className = "px-4 py-2.5 text-sm text-neutral-700 hover:bg-neutral-50 cursor-pointer transition-colors"
      item.addEventListener("click", () => this.#selectResult(result))
      this.dropdownTarget.appendChild(item)
    })

    this.dropdownTarget.classList.remove("hidden")
  }

  #selectResult(result) {
    const address  = result.raw?.address || {}
    const city     = address.city || address.town || address.village || address.municipality || ""
    const district = address.city_district || address.suburb || address.neighbourhood || ""
    const display  = city && district ? `${city} - ${district}` : city || district || result.label

    this.inputTarget.value     = result.label
    this.nameTarget.value      = display
    this.latitudeTarget.value  = result.y
    this.longitudeTarget.value = result.x
    this.zipcodeTarget.value   = address.postcode || ""
    this.timezoneTarget.value  = tzlookup(result.y, result.x)

    this.submitTarget.disabled = false
    this.alertTarget.classList.add("hidden")
    this.#hideDropdown()
  }

  #hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.innerHTML = ""
  }

  #clearFields() {
    this.nameTarget.value      = ""
    this.latitudeTarget.value  = ""
    this.longitudeTarget.value = ""
    this.zipcodeTarget.value   = ""
    this.submitTarget.disabled = true
  }

  #placeSelected() {
    return this.latitudeTarget.value !== ""
  }

  #onOutsideClick = (e) => {
    if (!this.element.contains(e.target)) {
      this.#hideDropdown()
    }
  }
}