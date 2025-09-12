import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["codes"]
  static values = { codes: Array }

  async copyAllCodes() {
    try {
      // バックアップコードを改行区切りのテキストとしてコピー
      const codesText = this.codesValue.join('\n')
      await navigator.clipboard.writeText(codesText)
      
      // 成功フィードバック
      this.showCopySuccess()
      
    } catch (error) {
      console.error('コピーに失敗しました:', error)
      // フォールバック：テキストエリアを使った古い方式
      this.fallbackCopy()
    }
  }

  showCopySuccess() {
    const button = this.element.querySelector('[data-action*="copyAllCodes"]')
    if (button) {
      const originalContent = button.innerHTML
      
      // 成功アイコンと文字に変更
      button.innerHTML = `
        <svg class="w-4 h-4 mr-2 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
        </svg>
        <span class="text-green-600 font-medium">コピー完了</span>
      `
      
      button.classList.add('bg-green-50', 'border-green-300')
      button.classList.remove('bg-white', 'border-slate-300', 'hover:bg-slate-50')
      
      // 2秒後に元に戻す
      setTimeout(() => {
        button.innerHTML = originalContent
        button.classList.remove('bg-green-50', 'border-green-300')
        button.classList.add('bg-white', 'border-slate-300', 'hover:bg-slate-50')
      }, 2000)
    }
  }

  fallbackCopy() {
    // 古いブラウザ用のフォールバック
    const textArea = document.createElement('textarea')
    textArea.value = this.codesValue.join('\n')
    textArea.style.position = 'fixed'
    textArea.style.opacity = '0'
    document.body.appendChild(textArea)
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showCopySuccess()
    } catch (error) {
      console.error('フォールバックコピーも失敗しました:', error)
      alert('コピーに失敗しました。手動でコードをコピーしてください。')
    } finally {
      document.body.removeChild(textArea)
    }
  }

  // 個別のコードをコピーする場合（将来的に使用可能）
  async copySingleCode(event) {
    const code = event.target.closest('[data-code]').dataset.code
    try {
      await navigator.clipboard.writeText(code)
      // 個別コピー成功のフィードバック
    } catch (error) {
      console.error('個別コピーに失敗:', error)
    }
  }
}