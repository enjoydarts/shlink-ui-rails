import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
    static targets = ["btn", "label", "spinner"]
    connect() {
        this.element.addEventListener("turbo:submit-start", () => this.start())
        this.element.addEventListener("turbo:submit-end", () => this.stop())
    }
    start() { this.btnTarget.disabled = true; this.spinnerTarget.classList.remove("hidden") }
    stop() { this.btnTarget.disabled = false; this.spinnerTarget.classList.add("hidden") }
}
