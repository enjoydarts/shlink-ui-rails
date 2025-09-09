import { Controller } from "@hotwired/stimulus"

// アカウント削除確認モーダルを管理するController
export default class extends Controller {
  static targets = [
    "modal", "backdrop", "content", 
    "confirmButton", "cancelButton", 
    "passwordField", "confirmationField"
  ]
  
  static values = {
    isOauthUser: { type: Boolean, default: false }
  }

  connect() {
    // ESCキーでモーダルを閉じる
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  // モーダルを開く
  openModal() {
    // スクロールを無効化
    document.body.style.overflow = "hidden"
    
    // モーダルを表示
    this.modalTarget.classList.remove("hidden")
    
    // アニメーション効果
    requestAnimationFrame(() => {
      this.backdropTarget.style.opacity = "1"
      this.contentTarget.style.transform = "scale(1)"
      this.contentTarget.style.opacity = "1"
    })

    // 最初の入力フィールドにフォーカス
    this.focusFirstInput()
  }

  // モーダルを閉じる
  closeModal() {
    // フェードアウトアニメーション
    this.backdropTarget.style.opacity = "0"
    this.contentTarget.style.transform = "scale(0.95)"
    this.contentTarget.style.opacity = "0"
    
    // アニメーション完了後にモーダルを非表示
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.style.overflow = ""
      this.resetForm()
    }, 300)
  }

  // バックドロップクリックでモーダルを閉じる
  backdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.closeModal()
    }
  }

  // ESCキーでモーダルを閉じる
  handleKeydown(event) {
    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      this.closeModal()
    }
  }

  // 削除確認処理
  confirmDelete(event) {
    event.preventDefault()
    
    if (!this.validateInput()) {
      return
    }

    // ボタンをローディング状態に
    this.setButtonLoading(true)
    
    // フォームを送信
    this.submitForm()
  }

  // 入力値の検証
  validateInput() {
    if (this.isOauthUserValue) {
      // OAuth ユーザーの場合：「削除」の入力確認
      const confirmationValue = this.confirmationFieldTarget.value.trim()
      if (confirmationValue !== "削除") {
        this.showValidationError("削除を確認するため「削除」と正確に入力してください。")
        return false
      }
    } else {
      // 通常ユーザーの場合：パスワード確認
      const passwordValue = this.passwordFieldTarget.value.trim()
      if (passwordValue === "") {
        this.showValidationError("現在のパスワードを入力してください。")
        return false
      }
    }
    
    this.clearValidationError()
    return true
  }

  // バリデーションエラーの表示
  showValidationError(message) {
    // 既存のエラーメッセージを削除
    this.clearValidationError()
    
    // エラーメッセージを作成
    const errorDiv = document.createElement("div")
    errorDiv.className = "validation-error mt-2 p-2 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700"
    errorDiv.textContent = message
    
    // 入力フィールドの後に挿入
    const inputField = this.isOauthUserValue ? this.confirmationFieldTarget : this.passwordFieldTarget
    inputField.parentNode.appendChild(errorDiv)
    
    // 入力フィールドを赤色ボーダーに
    inputField.classList.add("border-red-500", "focus:border-red-500")
  }

  // バリデーションエラーのクリア
  clearValidationError() {
    const errorElements = this.element.querySelectorAll(".validation-error")
    errorElements.forEach(el => el.remove())
    
    // 入力フィールドの赤色ボーダーを削除
    const inputField = this.isOauthUserValue ? this.confirmationFieldTarget : this.passwordFieldTarget
    inputField.classList.remove("border-red-500", "focus:border-red-500")
  }

  // フォーム送信
  submitForm() {
    const form = this.element.querySelector("form")
    if (form) {
      form.submit()
    }
  }

  // 最初の入力フィールドにフォーカス
  focusFirstInput() {
    setTimeout(() => {
      const inputField = this.isOauthUserValue ? this.confirmationFieldTarget : this.passwordFieldTarget
      if (inputField) {
        inputField.focus()
      }
    }, 100)
  }

  // フォームのリセット
  resetForm() {
    if (this.hasPasswordFieldTarget) {
      this.passwordFieldTarget.value = ""
    }
    if (this.hasConfirmationFieldTarget) {
      this.confirmationFieldTarget.value = ""
    }
    this.clearValidationError()
    this.setButtonLoading(false)
  }

  // ボタンのローディング状態を設定
  setButtonLoading(isLoading) {
    if (isLoading) {
      this.confirmButtonTarget.disabled = true
      this.confirmButtonTarget.innerHTML = `
        削除中...
        <svg class="w-4 h-4 animate-spin inline ml-2" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      `
    } else {
      this.confirmButtonTarget.disabled = false
      this.confirmButtonTarget.innerHTML = "アカウントを削除する"
    }
  }
}