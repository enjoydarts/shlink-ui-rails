import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
    static targets = ["btn", "label", "spinner"]
    connect() {
        this.element.addEventListener("turbo:submit-start", () => this.start())
        this.element.addEventListener("turbo:submit-end", () => this.stop())
    }
    start() { 
        this.btnTarget.disabled = true
        this.spinnerTarget.classList.remove("hidden")
    }
    stop() { 
        // Turnstile検証が必要な場合は、検証完了時のみボタンを有効化
        const hasTurnstile = document.getElementById('turnstile-container')
        if (hasTurnstile && !window.turnstileVerified) {
            // Turnstile検証が未完了の場合はボタンを無効のまま
            this.btnTarget.disabled = true
            this.btnTarget.classList.add('opacity-50', 'cursor-not-allowed')
        } else {
            // Turnstile検証が完了している、またはTurnstileが無い場合
            this.btnTarget.disabled = false
            this.btnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        }
        this.spinnerTarget.classList.add("hidden")
    }
}
