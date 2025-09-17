import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast-trigger"
export default class extends Controller {
  static values = { message: String, type: String }

  connect() {
    // 要素が追加されたときにトーストを表示
    if (typeof showToast === 'function') {
      showToast(this.messageValue, this.typeValue)
    }

    // 要素を削除（不要になったため）
    this.element.remove()
  }

  show() {
    // イベントハンドラーとしても使用可能
    if (typeof showToast === 'function') {
      showToast(this.messageValue, this.typeValue)
    }
  }
}