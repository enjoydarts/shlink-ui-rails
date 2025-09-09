import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]
  static values = { open: Boolean }

  connect() {
    this.openValue = false
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  openValueChanged() {
    if (this.openValue) {
      this.showDropdown()
    } else {
      this.hideDropdown()
    }
  }

  showDropdown() {
    this.dropdownTarget.classList.remove("hidden", "opacity-0", "scale-95")
    this.dropdownTarget.classList.add("opacity-100", "scale-100")
    // Focus first link for accessibility
    const firstLink = this.dropdownTarget.querySelector("a")
    if (firstLink) firstLink.focus()
  }

  hideDropdown() {
    this.dropdownTarget.classList.remove("opacity-100", "scale-100")
    this.dropdownTarget.classList.add("opacity-0", "scale-95")
    setTimeout(() => {
      this.dropdownTarget.classList.add("hidden")
    }, 150)
  }
}