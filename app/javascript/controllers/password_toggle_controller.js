import { Controller } from "@hotwired/stimulus"

// パスワード入力欄の表示/非表示を切り替えるコントローラー
// data-controller="password-toggle"で使用
export default class extends Controller {
  static targets = ["input", "toggleButton", "showIcon", "hideIcon"]

  connect() {
    this.updateToggleState()
  }

  // パスワードの表示/非表示を切り替え
  toggle() {
    const isPasswordVisible = this.inputTarget.type === "text"
    
    if (isPasswordVisible) {
      this.hidePassword()
    } else {
      this.showPassword()
    }
  }

  // パスワードを表示
  showPassword() {
    this.inputTarget.type = "text"
    this.updateToggleState()
  }

  // パスワードを非表示
  hidePassword() {
    this.inputTarget.type = "password"
    this.updateToggleState()
  }

  // トグルボタンの状態を更新
  updateToggleState() {
    const isPasswordVisible = this.inputTarget.type === "text"
    
    if (this.hasShowIconTarget && this.hasHideIconTarget) {
      if (isPasswordVisible) {
        // パスワードが見えている時：非表示ボタン（目に斜線）を表示
        this.showIconTarget.classList.add("hidden")
        this.hideIconTarget.classList.remove("hidden")
      } else {
        // パスワードが隠れている時：表示ボタン（目）を表示
        this.showIconTarget.classList.remove("hidden")
        this.hideIconTarget.classList.add("hidden")
      }
    }

    // アクセシビリティのためのaria-label更新
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.setAttribute(
        "aria-label", 
        isPasswordVisible ? "パスワードを隠す" : "パスワードを表示"
      )
    }
  }
}