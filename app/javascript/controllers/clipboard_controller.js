import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
    static values = { text: String }
    connect() {
        this.textValue ||= this.element.dataset.clipboardText
        this.element.addEventListener("click", async () => {
            if (!this.textValue) return
            
            // Save original content
            const originalHTML = this.element.innerHTML
            
            try {
                await navigator.clipboard.writeText(this.textValue)
                
                // Success feedback with animation
                this.element.innerHTML = `
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                    <span>コピー済み!</span>
                `
                this.element.classList.add("bg-green-600", "hover:bg-green-700")
                this.element.classList.remove("bg-blue-600", "hover:bg-blue-700")
                
                setTimeout(() => {
                    this.element.innerHTML = originalHTML
                    this.element.classList.remove("bg-green-600", "hover:bg-green-700")
                    this.element.classList.add("bg-blue-600", "hover:bg-blue-700")
                }, 2000)
            } catch (err) {
                // Error feedback
                this.element.innerHTML = `
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                    <span>エラー</span>
                `
                this.element.classList.add("bg-red-600", "hover:bg-red-700")
                this.element.classList.remove("bg-blue-600", "hover:bg-blue-700")
                
                setTimeout(() => {
                    this.element.innerHTML = originalHTML
                    this.element.classList.remove("bg-red-600", "hover:bg-red-700")
                    this.element.classList.add("bg-blue-600", "hover:bg-blue-700")
                }, 2000)
            }
        })
    }
}
