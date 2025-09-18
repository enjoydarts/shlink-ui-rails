import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ["toggle"]
  static values = {
    current: String,
    system: Boolean
  }

  connect() {
    console.log('Theme controller connected with values:', {
      current: this.currentValue,
      system: this.systemValue
    })

    // すぐにテーマを適用（初期化前）
    this.applyThemeImmediate()

    this.initializeTheme()
    this.updateSystemTheme()

    // システム設定変更の監視
    if (this.systemValue) {
      this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
      this.mediaQuery.addEventListener('change', this.handleSystemThemeChange.bind(this))
    }
  }

  // 即座にテーマを適用
  applyThemeImmediate() {
    const theme = this.currentValue || 'system'
    console.log('Applying theme immediately:', theme)
    this.applyTheme(theme)
  }

  disconnect() {
    if (this.mediaQuery) {
      this.mediaQuery.removeEventListener('change', this.handleSystemThemeChange.bind(this))
    }
  }

  // 初期テーマ設定
  initializeTheme() {
    const theme = this.currentValue || 'system'
    this.applyTheme(theme)
  }

  // テーマ適用
  applyTheme(theme) {
    const html = document.documentElement
    console.log('Applying theme:', theme, 'to html element:', html)

    switch (theme) {
      case 'light':
        html.classList.remove('dark')
        console.log('Removed dark class, current classes:', html.className)
        break
      case 'dark':
        html.classList.add('dark')
        console.log('Added dark class, current classes:', html.className)
        break
      case 'system':
        this.applySystemTheme()
        break
    }

    this.currentValue = theme
    this.updateToggleButton(theme)
  }

  // システムテーマ適用
  applySystemTheme() {
    const html = document.documentElement
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    console.log('System theme check - prefers dark:', prefersDark)

    if (prefersDark) {
      html.classList.add('dark')
      console.log('Added dark class for system theme, current classes:', html.className)
    } else {
      html.classList.remove('dark')
      console.log('Removed dark class for system theme, current classes:', html.className)
    }
  }

  // システム設定変更時の処理
  handleSystemThemeChange() {
    if (this.currentValue === 'system') {
      this.applySystemTheme()
    }
  }

  // システムテーマ更新（設定ページ用）
  updateSystemTheme() {
    this.systemValue = this.currentValue === 'system'
  }

  // トグルボタンの表示更新
  updateToggleButton(theme) {
    if (!this.hasToggleTarget) return

    const button = this.toggleTarget
    const isDark = theme === 'dark' ||
                   (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)

    // アイコンとテキストの更新
    this.updateButtonContent(button, theme, isDark)
  }

  // ボタン内容の更新
  updateButtonContent(button, theme, isDark) {
    const icon = button.querySelector('[data-theme-icon]')
    const text = button.querySelector('[data-theme-text]')

    if (icon) {
      switch (theme) {
        case 'light':
          icon.innerHTML = this.getLightIcon()
          break
        case 'dark':
          icon.innerHTML = this.getDarkIcon()
          break
        case 'system':
          icon.innerHTML = this.getSystemIcon()
          break
      }
    }

    if (text) {
      switch (theme) {
        case 'light':
          text.textContent = 'ライト'
          break
        case 'dark':
          text.textContent = 'ダーク'
          break
        case 'system':
          text.textContent = 'システム'
          break
      }
    }

    // ダークモード時のボタンスタイル調整
    if (isDark) {
      button.classList.add('dark-theme')
    } else {
      button.classList.remove('dark-theme')
    }
  }

  // テーマサイクル切り替え
  toggle() {
    const themes = ['light', 'dark', 'system']
    const currentIndex = themes.indexOf(this.currentValue)
    const nextTheme = themes[(currentIndex + 1) % themes.length]

    this.applyTheme(nextTheme)
    this.saveThemePreference(nextTheme)
  }

  // テーマ設定の保存（Ajax）
  async saveThemePreference(theme) {
    try {
      const response = await fetch('/account', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          user: {
            theme_preference: theme
          }
        })
      })

      if (response.ok) {
        this.showNotification('テーマを更新しました', 'success')
      } else {
        throw new Error('Update failed')
      }
    } catch (error) {
      console.error('Theme update failed:', error)
      this.showNotification('テーマの更新に失敗しました', 'error')
    }
  }

  // 通知表示
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transition-all duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' :
      type === 'error' ? 'bg-red-500 text-white' :
      'bg-blue-500 text-white'
    }`
    notification.textContent = message

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.classList.add('opacity-0', 'translate-y-2')
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  // アイコンSVG
  getLightIcon() {
    return `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12,8A4,4 0 0,0 8,12A4,4 0 0,0 12,16A4,4 0 0,0 16,12A4,4 0 0,0 12,8M12,18A6,6 0 0,1 6,12A6,6 0 0,1 12,6A6,6 0 0,1 18,12A6,6 0 0,1 12,18M20,8.69V4H15.31L12,0.69L8.69,4H4V8.69L0.69,12L4,15.31V20H8.69L12,23.31L15.31,20H20V15.31L23.31,12L20,8.69Z"/>
    </svg>`
  }

  getDarkIcon() {
    return `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M17.75,4.09L15.22,6.03L16.13,9.09L13.5,7.28L10.87,9.09L11.78,6.03L9.25,4.09L12.44,4L13.5,1L14.56,4L17.75,4.09M21.25,11L19.61,12.25L20.2,14.23L18.5,13.06L16.8,14.23L17.39,12.25L15.75,11L17.81,10.95L18.5,9L19.19,10.95L21.25,11M18.97,15.95C19.8,15.87 20.69,17.05 20.16,17.8C19.84,18.25 19.5,18.67 19.08,19.07C15.17,23 8.84,23 4.94,19.07C1.03,15.17 1.03,8.83 4.94,4.93C5.34,4.53 5.76,4.17 6.21,3.85C6.96,3.32 8.14,4.21 8.06,5.04C7.79,7.9 8.75,10.87 10.95,13.06C13.14,15.26 16.1,16.22 18.97,15.95M17.33,17.97C14.5,17.81 11.7,16.64 9.53,14.5C7.36,12.31 6.2,9.5 6.04,6.68C3.23,9.82 3.34,14.4 6.35,17.41C9.37,20.43 14,20.54 17.33,17.97Z"/>
    </svg>`
  }

  getSystemIcon() {
    return `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M4,6H20V16H4M20,18A2,2 0 0,0 22,16V6C22,4.89 21.1,4 20,4H4C2.89,4 2,4.89 2,6V16A2,2 0 0,0 4,18H0V20H24V20H20Z"/>
    </svg>`
  }
}