import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "chevron"]

  connect() {
    // 初期状態では閉じておく
    this.contentTarget.style.maxHeight = "0"
    this.contentTarget.style.overflow = "hidden"
    this.contentTarget.style.transition = "max-height 0.3s ease-out"
  }

  toggle() {
    if (this.contentTarget.style.maxHeight === "0px") {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
    this.chevronTarget.style.transform = "rotate(180deg)"
  }

  close() {
    this.contentTarget.style.maxHeight = "0"
    this.chevronTarget.style.transform = "rotate(0deg)"
  }
}