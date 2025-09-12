import { Controller } from "@hotwired/stimulus"

// モーダル表示制御用のStimulusコントローラー
export default class extends Controller {
  static values = { target: String }

  open(event) {
    event.preventDefault()
    
    const targetSelector = this.targetValue || event.currentTarget.dataset.modalTargetValue
    const modal = document.querySelector(targetSelector)
    
    if (modal) {
      // bodyのスクロールを無効化
      document.body.style.overflow = 'hidden'
      
      modal.classList.remove('hidden')
      
      // 美しい開始アニメーション
      requestAnimationFrame(() => {
        const backdrop = modal.querySelector('.fixed.inset-0')
        const content = modal.querySelector('[class*="scale-"]')
        
        if (backdrop) {
          backdrop.style.opacity = '0'
          backdrop.style.transition = 'opacity 300ms cubic-bezier(0.16, 1, 0.3, 1)'
          requestAnimationFrame(() => backdrop.style.opacity = '1')
        }
        
        if (content) {
          content.style.transform = 'scale(0.95) translateY(10px)'
          content.style.opacity = '0'
          content.style.transition = 'all 300ms cubic-bezier(0.16, 1, 0.3, 1)'
          requestAnimationFrame(() => {
            content.style.transform = 'scale(1) translateY(0)'
            content.style.opacity = '1'
          })
        }
      })
      
      // モーダル背景クリックで閉じる
      modal.addEventListener('click', this.handleBackgroundClick.bind(this))
      // ESCキーで閉じる
      document.addEventListener('keydown', this.handleEscKey.bind(this))
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    const modal = this.element.closest('.fixed') || document.querySelector('.fixed:not(.hidden)')
    if (modal) {
      // 美しい終了アニメーション
      const backdrop = modal.querySelector('.fixed.inset-0')
      const content = modal.querySelector('[class*="scale-"]')
      
      if (backdrop) {
        backdrop.style.transition = 'opacity 200ms ease-out'
        backdrop.style.opacity = '0'
      }
      
      if (content) {
        content.style.transition = 'all 200ms ease-out'
        content.style.transform = 'scale(0.95) translateY(-10px)'
        content.style.opacity = '0'
      }
      
      // アニメーション完了後にモーダルを隠す
      setTimeout(() => {
        modal.classList.add('hidden')
        document.body.style.overflow = '' // bodyスクロール復元
        
        // イベントリスナーを削除
        modal.removeEventListener('click', this.handleBackgroundClick.bind(this))
        document.removeEventListener('keydown', this.handleEscKey.bind(this))
      }, 200)
    }
  }

  handleBackgroundClick(event) {
    // モーダルの背景部分またはコンテンツエリアの外側をクリックした場合のみ閉じる
    if (event.target === event.currentTarget || 
        event.target.classList.contains('bg-black') ||
        event.target.classList.contains('backdrop-blur-sm')) {
      this.close()
    }
  }

  handleEscKey(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  disconnect() {
    // コントローラー削除時にイベントリスナーをクリーンアップ
    document.removeEventListener('keydown', this.handleEscKey.bind(this))
  }
}