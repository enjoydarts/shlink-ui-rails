import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // メニューの初期状態を設定
    this.close()
  }

  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.menuTarget.classList.add("block")
    // アニメーション用のクラスを追加
    setTimeout(() => {
      this.menuTarget.classList.add("opacity-100", "translate-y-0")
      this.menuTarget.classList.remove("opacity-0", "-translate-y-2")
    }, 10)
  }

  close() {
    this.menuTarget.classList.add("opacity-0", "-translate-y-2")
    this.menuTarget.classList.remove("opacity-100", "translate-y-0")
    // アニメーション完了後に非表示
    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
      this.menuTarget.classList.remove("block")
    }, 200)
  }

  isOpen() {
    return !this.menuTarget.classList.contains("hidden")
  }

  // 外部クリックでメニューを閉じる
  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  // Escキーでメニューを閉じる
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}