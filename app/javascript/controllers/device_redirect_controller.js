import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "toggleBtn", "enabledField", "androidUrl", "iosUrl", "desktopUrl"]

  connect() {
    this.updateButtonText()
    this.checkInitialState()
  }

  toggle() {
    this.containerTarget.classList.toggle("hidden")

    const isVisible = !this.containerTarget.classList.contains("hidden")
    this.enabledFieldTarget.value = isVisible ? "true" : "false"

    // 表示後にスクロールして見えるようにする
    if (isVisible) {
      setTimeout(() => {
        this.containerTarget.scrollIntoView({
          behavior: 'smooth',
          block: 'nearest',
          inline: 'nearest'
        })
      }, 100)
    }

    this.updateButtonText()
  }

  updateButtonText() {
    const isVisible = !this.containerTarget.classList.contains("hidden")
    // 初期テキストまたは現在のテキストで判定
    const isCreateForm = this.toggleBtnTarget.textContent.includes("有効") ||
                        this.toggleBtnTarget.textContent.includes("無効")

    if (isCreateForm) {
      this.toggleBtnTarget.textContent = isVisible ? "無効にする" : "有効にする"
    } else {
      this.toggleBtnTarget.textContent = isVisible ? "閉じる" : "編集"
    }
  }

  checkInitialState() {
    // 編集時に既存のデバイス別URLがあるかチェック
    const hasAndroidUrl = this.androidUrlTarget.value.trim() !== ""
    const hasIosUrl = this.iosUrlTarget.value.trim() !== ""
    const hasDesktopUrl = this.desktopUrlTarget.value.trim() !== ""

    if (hasAndroidUrl || hasIosUrl || hasDesktopUrl) {
      this.containerTarget.classList.remove("hidden")
      this.enabledFieldTarget.value = "true"
      this.updateButtonText()
    }
  }
}