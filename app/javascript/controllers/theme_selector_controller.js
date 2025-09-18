import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme-selector"
export default class extends Controller {
  static targets = ["preview", "previewArea"]

  connect() {
    // 現在の設定でテーマを初期化
    this.initializeCurrentTheme()
  }

  // 現在の設定を反映
  initializeCurrentTheme() {
    const checkedRadio = this.element.querySelector('input[type="radio"]:checked')
    if (checkedRadio) {
      this.previewTheme({ target: checkedRadio })
    }
  }

  // テーマプレビュー
  previewTheme(event) {
    const selectedTheme = event.target.value
    this.applyPreview(selectedTheme)
    this.showPreview(selectedTheme)
  }

  // プレビュー適用
  applyPreview(theme) {
    const html = document.documentElement

    switch (theme) {
      case 'light':
        html.classList.remove('dark')
        break
      case 'dark':
        html.classList.add('dark')
        break
      case 'system':
        // システム設定に従う
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
        if (prefersDark) {
          html.classList.add('dark')
        } else {
          html.classList.remove('dark')
        }
        break
    }
  }

  // プレビューエリア表示
  showPreview(theme) {
    if (!this.hasPreviewTarget || !this.hasPreviewAreaTarget) return

    const preview = this.previewTarget
    const previewArea = this.previewAreaTarget

    // プレビューエリアにサンプルコンテンツを設定
    this.updatePreviewContent(previewArea, theme)

    // プレビューエリアを表示
    preview.classList.remove('hidden')

    // スムーズなアニメーション
    setTimeout(() => {
      preview.classList.add('opacity-100', 'translate-y-0')
    }, 10)
  }

  // プレビューコンテンツ更新
  updatePreviewContent(previewArea, theme) {
    const isDark = theme === 'dark' ||
                   (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)

    if (isDark) {
      previewArea.className = "mt-2 p-3 rounded-lg bg-gray-800 text-white border border-gray-700"
    } else {
      previewArea.className = "mt-2 p-3 rounded-lg bg-white text-gray-900 border border-gray-200"
    }

    previewArea.innerHTML = `
      <p class="font-medium">
        ${this.getThemeDisplayName(theme)}のプレビュー
      </p>
      <p class="text-sm opacity-75 mt-1">
        ${this.getThemeDescription(theme)}
      </p>
    `
  }

  // テーマ表示名取得
  getThemeDisplayName(theme) {
    switch (theme) {
      case 'light':
        return 'ライトモード'
      case 'dark':
        return 'ダークモード'
      case 'system':
        return 'システム設定'
      default:
        return 'テーマ'
    }
  }

  // テーマ説明取得
  getThemeDescription(theme) {
    switch (theme) {
      case 'light':
        return '明るい配色で表示されます'
      case 'dark':
        return '目に優しい暗い配色で表示されます'
      case 'system':
        return 'デバイスの設定に応じて自動で切り替わります'
      default:
        return ''
    }
  }

  // フォーム送信成功時の処理
  handleSuccess(event) {
    const [data, status, xhr] = event.detail
    console.log('Theme form success:', data)

    // レスポンスデータからテーマを取得
    const responseData = typeof data === 'string' ? JSON.parse(data) : data

    if (responseData.success && responseData.theme) {
      // テーマをドキュメントに適用
      this.applyThemeToDocument(responseData.theme)
      console.log('Applied theme from form:', responseData.theme)
    }

    // 成功通知の表示
    this.showNotification('テーマ設定を更新しました！', 'success')

    // プレビューエリアを隠す
    if (this.hasPreviewTarget) {
      setTimeout(() => {
        this.previewTarget.classList.add('hidden')
      }, 2000)
    }
  }

  // テーマをドキュメントに適用
  applyThemeToDocument(theme) {
    const html = document.documentElement
    console.log('Applying theme to document:', theme, 'current classes:', html.className)

    switch (theme) {
      case "light":
        html.classList.remove("dark")
        console.log('Light theme applied, current classes:', html.className)
        break
      case "dark":
        html.classList.add("dark")
        console.log('Dark theme applied, current classes:', html.className)
        break
      case "system":
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
        console.log('System theme - prefers dark:', prefersDark)
        if (prefersDark) {
          html.classList.add("dark")
        } else {
          html.classList.remove("dark")
        }
        console.log('System theme applied, current classes:', html.className)
        break
    }
  }

  // 通知表示
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    const baseClasses = 'fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transition-all duration-300 transform translate-y-0 opacity-100'

    let typeClasses = ''
    switch (type) {
      case 'success':
        typeClasses = 'bg-green-500 text-white'
        break
      case 'error':
        typeClasses = 'bg-red-500 text-white'
        break
      default:
        typeClasses = 'bg-blue-500 text-white'
    }

    notification.className = `${baseClasses} ${typeClasses}`
    notification.innerHTML = `
      <div class="flex items-center">
        <div class="flex-shrink-0">
          ${this.getNotificationIcon(type)}
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium">${message}</p>
        </div>
      </div>
    `

    document.body.appendChild(notification)

    // 自動で消去
    setTimeout(() => {
      notification.classList.add('opacity-0', 'translate-y-2')
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  // 通知アイコン取得
  getNotificationIcon(type) {
    switch (type) {
      case 'success':
        return `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>`
      case 'error':
        return `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
        </svg>`
      default:
        return `<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
        </svg>`
    }
  }
}