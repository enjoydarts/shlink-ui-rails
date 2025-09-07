import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenInput", "tagContainer"]
  static values = { maxTags: { type: Number, default: 10 }, maxLength: { type: Number, default: 20 } }

  connect() {
    this.tags = new Set()
    this.loadExistingTags()
    this.updateHiddenInput()
  }

  // 既存のタグを読み込み（編集フォーム対応）
  loadExistingTags() {
    const existingTags = this.hiddenInputTarget.value
    if (existingTags && existingTags.trim() !== '') {
      const tags = existingTags.split(',').map(tag => tag.trim()).filter(tag => tag !== '')
      tags.forEach(tag => this.tags.add(tag))
      this.renderTags()
    }
  }

  // エンターキーでタグを追加
  handleKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.addTag()
    }
  }

  // タグを追加
  addTag() {
    const input = this.inputTarget
    const tagText = input.value.trim()

    // バリデーション
    if (!this.validateTag(tagText)) {
      return
    }

    // タグを追加
    this.tags.add(tagText)
    input.value = ''
    this.renderTags()
    this.updateHiddenInput()
    this.clearErrors()
  }

  // タグのバリデーション
  validateTag(tagText) {
    // 空文字チェック
    if (tagText === '') {
      this.showError('タグを入力してください')
      return false
    }

    // 文字数チェック
    if (tagText.length > this.maxLengthValue) {
      this.showError(`タグは${this.maxLengthValue}文字以内で入力してください`)
      return false
    }

    // 重複チェック
    if (this.tags.has(tagText)) {
      this.showError('同じタグが既に追加されています')
      return false
    }

    // 最大数チェック
    if (this.tags.size >= this.maxTagsValue) {
      this.showError(`タグは最大${this.maxTagsValue}個まで設定できます`)
      return false
    }

    return true
  }

  // タグを削除
  removeTag(event) {
    const tagText = event.target.dataset.tag
    this.tags.delete(tagText)
    this.renderTags()
    this.updateHiddenInput()
    this.clearErrors()
  }

  // タグのレンダリング
  renderTags() {
    const container = this.tagContainerTarget
    container.innerHTML = ''

    this.tags.forEach(tag => {
      const tagElement = this.createTagElement(tag)
      container.appendChild(tagElement)
    })
  }

  // タグ要素を作成
  createTagElement(tag) {
    const tagElement = document.createElement('div')
    tagElement.className = 'inline-flex items-center gap-1 px-3 py-1 bg-purple-100 text-purple-800 border border-purple-200 rounded-full text-sm font-medium'
    
    tagElement.innerHTML = `
      <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
      </svg>
      <span>${this.escapeHtml(tag)}</span>
      <button type="button" 
              class="ml-1 text-purple-600 hover:text-purple-800 hover:bg-purple-200 rounded-full p-0.5 transition-colors duration-200" 
              data-action="click->tag-input#removeTag" 
              data-tag="${this.escapeHtml(tag)}"
              title="タグを削除">
        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    `
    
    return tagElement
  }

  // HTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // 隠しフィールドを更新
  updateHiddenInput() {
    const tagsArray = Array.from(this.tags)
    this.hiddenInputTarget.value = tagsArray.join(', ')
  }

  // エラーメッセージを表示
  showError(message) {
    this.clearErrors()
    const errorElement = document.createElement('div')
    errorElement.className = 'text-red-600 text-sm mt-1'
    errorElement.textContent = message
    errorElement.setAttribute('data-tag-error', '')
    
    this.inputTarget.parentNode.appendChild(errorElement)
    this.inputTarget.classList.add('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
  }

  // エラーメッセージをクリア
  clearErrors() {
    const errorElements = this.element.querySelectorAll('[data-tag-error]')
    errorElements.forEach(element => element.remove())
    
    this.inputTarget.classList.remove('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
  }

  // 入力フィールドにフォーカス
  focusInput() {
    this.inputTarget.focus()
  }
}