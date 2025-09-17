import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit-form"
export default class extends Controller {
  async submit(event) {
    event.preventDefault()

    const form = this.element
    const submitButton = document.getElementById('update-btn')
    const buttonText = submitButton ? submitButton.querySelector('#update-btn-text') : null
    const buttonSpinner = submitButton ? submitButton.querySelector('#update-btn-spinner') : null
    const originalText = buttonText ? buttonText.textContent : '更新'

    // ボタンをローディング状態にする
    if (submitButton && buttonText && buttonSpinner) {
      submitButton.disabled = true
      buttonText.textContent = '更新中...'
      buttonSpinner.classList.remove('hidden')
    }

    try {
      const formData = new FormData(form)
      const response = await fetch(form.action, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // 成功時
        this.hideValidationErrors() // エラーメッセージをクリア
        showToast('短縮URLを更新しました', 'success')

        // モーダルを閉じる
        const modal = document.getElementById('edit-modal')
        if (modal) {
          modal.classList.add('hidden')
        }

        // ページをリロードして最新データを表示
        setTimeout(() => {
          window.location.reload()
        }, 1000)
      } else {
        // エラー時（422を含む）
        let errorMessage = '更新に失敗しました'

        if (data) {
          if (data.message) {
            errorMessage = data.message
          } else if (data.errors && data.errors.length > 0) {
            errorMessage = data.errors.join(', ')
          }
        }

        showToast(errorMessage, 'error')

        // バリデーションエラーをモーダル内に表示
        this.showValidationErrors(data.errors || [errorMessage])

        // ボタンを元に戻す
        if (submitButton && buttonText && buttonSpinner) {
          submitButton.disabled = false
          buttonText.textContent = originalText
          buttonSpinner.classList.add('hidden')
        }
      }
    } catch (error) {
      console.error('Update error:', error)
      showToast('ネットワークエラーが発生しました', 'error')

      // ボタンを元に戻す
      if (submitButton && buttonText && buttonSpinner) {
        submitButton.disabled = false
        buttonText.textContent = originalText
        buttonSpinner.classList.add('hidden')
      }
    }
  }

  showValidationErrors(errors) {
    // 既存のエラーメッセージを削除
    const existingErrors = document.querySelector('.validation-errors')
    if (existingErrors) {
      existingErrors.remove()
    }

    if (!errors || errors.length === 0) {
      return
    }

    // エラーメッセージのHTMLを作成
    const errorDiv = document.createElement('div')
    errorDiv.className = 'validation-errors mx-4 sm:mx-6 mt-4 bg-red-50 border border-red-200 rounded-lg p-4'

    const errorContent = `
      <div class="flex">
        <svg class="w-5 h-5 text-red-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">入力内容を確認してください</h3>
          <div class="mt-2 text-sm text-red-700">
            <ul class="list-disc list-inside space-y-1">
              ${errors.map(error => `<li>${error}</li>`).join('')}
            </ul>
          </div>
        </div>
      </div>
    `

    errorDiv.innerHTML = errorContent

    // モーダルヘッダーの後に挿入
    const modalHeader = document.querySelector('#edit-modal-content .border-b')

    if (modalHeader) {
      modalHeader.parentNode.insertBefore(errorDiv, modalHeader.nextSibling)
    } else {
      const modalContent = document.querySelector('#edit-modal-content')
      if (modalContent) {
        modalContent.insertBefore(errorDiv, modalContent.children[1])
      }
    }
  }

  hideValidationErrors() {
    const existingErrors = document.querySelector('.validation-errors')
    if (existingErrors) {
      existingErrors.remove()
    }
  }
}