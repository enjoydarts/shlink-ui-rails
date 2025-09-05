import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    autoHide: Boolean,
    delay: { type: Number, default: 5000 }
  }

  connect() {
    // トーストの位置を調整（複数のトーストがある場合に重ならないように）
    this.adjustPosition()
    
    // 初期状態: 右に隠れている
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    this.element.style.transition = "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)"
    
    // スライドインアニメーション
    requestAnimationFrame(() => {
      this.element.style.transform = "translateX(0)"
      this.element.style.opacity = "1"
    })

    if (this.autoHideValue) {
      this.scheduleHide()
    }
  }

  adjustPosition() {
    // 既存のトーストの数をカウント
    const existingToasts = document.querySelectorAll('[data-controller*="flash"]')
    const index = Array.from(existingToasts).indexOf(this.element)
    
    // 各トーストを垂直方向にずらす
    if (index > 0) {
      this.element.style.top = `${1 + (index * 5)}rem`
    }
  }

  scheduleHide() {
    this.timeout = setTimeout(() => {
      this.hide()
    }, this.delayValue)
  }

  hide() {
    this.element.style.transition = "all 0.4s cubic-bezier(0.16, 1, 0.3, 1)"
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    
    setTimeout(() => {
      this.element.remove()
      this.reorderToasts()
    }, 400)
  }

  reorderToasts() {
    // 残りのトーストの位置を再調整
    const remainingToasts = document.querySelectorAll('[data-controller*="flash"]')
    remainingToasts.forEach((toast, index) => {
      toast.style.top = `${1 + (index * 5)}rem`
    })
  }

  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.hide()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}