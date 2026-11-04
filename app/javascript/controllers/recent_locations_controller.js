import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "helios:recent_locations"
const MAX_ENTRIES = 10

export default class extends Controller {
  static targets = ["list"]
  static values  = { formId: String }

  connect() {
    this.render()
  }

  add({ detail: location }) {
    const locations = this.#stored()
    const deduped   = locations.filter(l => l.name !== location.name)
    const updated   = [location, ...deduped].slice(0, MAX_ENTRIES)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated))
    this.render()
  }

  render() {
    this.listTarget.innerHTML = ""
    this.#stored().forEach(location => {
      const li = document.createElement("li")
      li.innerHTML = `
        <button class="w-full text-left px-3 py-2 rounded-lg text-sm
                       text-neutral-700
                       hover:bg-neutral-300/50
                       transition-colors truncate">
          ${location.name}
        </button>
      `
      li.querySelector("button").addEventListener("click", () => this.#fetch(location))
      this.listTarget.appendChild(li)
    })
  }

  #fetch(location) {
    const form = document.getElementById(this.formIdValue)
    if (!form) return

    form.querySelector("[data-places-target='name']").value      = location.name
    form.querySelector("[data-places-target='latitude']").value  = location.latitude
    form.querySelector("[data-places-target='longitude']").value = location.longitude
    form.querySelector("[data-places-target='zipcode']").value   = location.zipcode
    form.querySelector("[data-places-target='timezone']").value   = location.timezone
    form.querySelector("[data-places-target='input']").value     = location.name

    form.requestSubmit()
  }

  #stored() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]")
    } catch {
      return []
    }
  }
}