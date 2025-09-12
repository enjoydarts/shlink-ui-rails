import { Controller } from "@hotwired/stimulus"

// WebAuthn操作を管理するStimulusコントローラー
export default class extends Controller {
  static targets = ["nicknameInput", "errorMessage", "editForm", "editInput", "displayName"]
  static values = { credentialId: Number, optionsUrl: String }
  
  connect() {
    console.log("WebAuthn controller connected")
  }
  
  // セキュリティキーの登録を開始
  async register(event) {
    event.preventDefault()
    
    try {
      this.hideError()
      this.showLoading("セキュリティキーの登録準備中...")
      
      // 登録用オプションを取得
      const optionsResponse = await fetch('/users/webauthn_credentials/registration_options', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (!optionsResponse.ok) {
        const error = await optionsResponse.json()
        throw new Error(error.error || '登録準備に失敗しました')
      }
      
      const options = await optionsResponse.json()
      console.log('Registration options:', options)
      
      // WebAuthn APIでクレデンシャルを作成
      this.showLoading("セキュリティキーでの操作を完了してください...")
      const credential = await this.createCredential(options)
      
      // サーバーに登録
      this.showLoading("登録を完了しています...")
      await this.submitRegistration(credential)
      
      this.showSuccess("セキュリティキーを登録しました")
      
      // ページをリロードして最新の状態を表示（セキュリティタブを維持）
      setTimeout(() => {
        console.log('Force reloading page after WebAuthn registration')
        // セキュリティタブのハッシュを保持してリロード
        const currentUrl = new URL(window.location.href)
        currentUrl.hash = '#security'
        // タイムスタンプを追加してキャッシュを無効化
        currentUrl.searchParams.set('_t', Date.now().toString())
        window.location.href = currentUrl.href
      }, 1500)
      
    } catch (error) {
      console.error('WebAuthn registration failed:', error)
      
      // エラーメッセージをより詳しく分析
      const errorMessage = this.getWebAuthnErrorMessage(error)
      this.showError(errorMessage)
    }
  }
  
  // 認証を実行（ログイン時など）
  async authenticate() {
    try {
      this.hideError()
      this.showLoading("認証準備中...")
      
      // 認証用オプションを取得（data属性から動的にURLを取得）
      const optionsUrl = this.hasOptionsUrlValue ? this.optionsUrlValue : '/users/webauthn_credentials/authentication_options'
      const optionsResponse = await fetch(optionsUrl, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (!optionsResponse.ok) {
        const error = await optionsResponse.json()
        throw new Error(error.error || '認証準備に失敗しました')
      }
      
      const options = await optionsResponse.json()
      console.log('Authentication options:', options)
      
      // WebAuthn APIで認証
      this.showLoading("セキュリティキーでの操作を完了してください...")
      const credential = await this.getCredential(options)
      
      // 認証に成功した場合、2FA認証フォームに送信
      this.showLoading("認証を完了しています...")
      await this.submitAuthentication(credential)
      
    } catch (error) {
      console.error('WebAuthn authentication failed:', error)
      
      // エラーメッセージをより詳しく分析（認証用）
      const errorMessage = this.getWebAuthnAuthErrorMessage(error)
      this.showError(errorMessage)
    }
  }
  
  // 認証をサーバーに送信
  async submitAuthentication(credential) {
    // 隠しフォームを作成してWebAuthn認証情報を送信
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/users/two_factor_authentications/verify'
    
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = this.getCSRFToken()
    form.appendChild(csrfInput)
    
    const credentialInput = document.createElement('input')
    credentialInput.type = 'hidden'
    credentialInput.name = 'webauthn_credential'
    credentialInput.value = JSON.stringify(credential)
    form.appendChild(credentialInput)
    
    document.body.appendChild(form)
    form.submit()
  }
  
  // WebAuthn APIでクレデンシャルを作成
  async createCredential(options) {
    // Base64URLデコード
    const challenge = this.base64urlDecode(options.challenge)
    const userId = this.base64urlDecode(options.user.id)
    
    // exclude credentialsをデコード
    const excludeCredentials = options.excludeCredentials?.map(cred => ({
      id: this.base64urlDecode(cred.id),
      type: cred.type
    })) || []
    
    const createOptions = {
      challenge: challenge,
      rp: options.rp,
      user: {
        id: userId,
        name: options.user.name,
        displayName: options.user.displayName
      },
      pubKeyCredParams: options.pubKeyCredParams,
      excludeCredentials: excludeCredentials,
      authenticatorSelection: options.authenticatorSelection,
      timeout: options.timeout
    }
    
    console.log('Create options:', createOptions)
    
    const credential = await navigator.credentials.create({
      publicKey: createOptions
    })
    
    if (!credential) {
      const cancelError = new Error('セキュリティキーでの操作がキャンセルされました')
      cancelError.name = 'NotAllowedError'
      throw cancelError
    }
    
    // レスポンスをサーバー送信用に変換
    return {
      id: credential.id,
      rawId: this.arrayBufferToBase64url(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: this.arrayBufferToBase64url(credential.response.clientDataJSON),
        attestationObject: this.arrayBufferToBase64url(credential.response.attestationObject)
      }
    }
  }
  
  // WebAuthn APIで認証
  async getCredential(options) {
    // Base64URLデコード
    const challenge = this.base64urlDecode(options.challenge)
    
    // allow credentialsをデコード
    const allowCredentials = options.allowCredentials?.map(cred => ({
      id: this.base64urlDecode(cred.id),
      type: cred.type
    })) || []
    
    const getOptions = {
      challenge: challenge,
      allowCredentials: allowCredentials,
      timeout: options.timeout,
      userVerification: options.userVerification
    }
    
    console.log('Get options:', getOptions)
    
    const credential = await navigator.credentials.get({
      publicKey: getOptions
    })
    
    if (!credential) {
      const cancelError = new Error('セキュリティキーでの操作がキャンセルされました')
      cancelError.name = 'NotAllowedError'
      throw cancelError
    }
    
    // レスポンスをサーバー送信用に変換
    return {
      id: credential.id,
      rawId: this.arrayBufferToBase64url(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: this.arrayBufferToBase64url(credential.response.clientDataJSON),
        authenticatorData: this.arrayBufferToBase64url(credential.response.authenticatorData),
        signature: this.arrayBufferToBase64url(credential.response.signature),
        userHandle: credential.response.userHandle ? this.arrayBufferToBase64url(credential.response.userHandle) : null
      }
    }
  }
  
  // 登録をサーバーに送信
  async submitRegistration(credential) {
    const nickname = this.hasNicknameInputTarget ? this.nicknameInputTarget.value : null
    
    const response = await fetch('/users/webauthn_credentials', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      body: JSON.stringify({
        credential: JSON.stringify(credential),
        nickname: nickname
      })
    })
    
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || '登録の完了に失敗しました')
    }
    
    return await response.json()
  }
  
  // エラーメッセージを表示
  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove('hidden')
    } else {
      alert(message)
    }
  }
  
  // エラーメッセージを隠す
  hideError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.classList.add('hidden')
    }
  }
  
  // 成功メッセージを表示
  showSuccess(message) {
    // 簡単な成功通知
    const successDiv = document.createElement('div')
    successDiv.className = 'fixed top-4 right-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded z-50'
    successDiv.textContent = message
    document.body.appendChild(successDiv)
    
    setTimeout(() => {
      document.body.removeChild(successDiv)
    }, 3000)
  }
  
  // ローディング状態を表示
  showLoading(message) {
    console.log(`Loading: ${message}`)
    // 実際のアプリケーションでは適切なローディングUIを表示
  }
  
  // CSRF トークンを取得
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
  
  // Base64URL デコード
  base64urlDecode(str) {
    // パディングを追加
    const padding = '='.repeat((4 - str.length % 4) % 4)
    const base64 = str.replace(/-/g, '+').replace(/_/g, '/') + padding
    
    // Base64デコードしてArrayBufferに変換
    const binary = atob(base64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i)
    }
    return bytes.buffer
  }
  
  // ArrayBuffer を Base64URL エンコード
  arrayBufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ''
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  }
  
  // WebAuthn認証エラーメッセージを日本語化
  getWebAuthnAuthErrorMessage(error) {
    console.log('Analyzing auth error:', error.name, error.message)
    
    // ユーザーキャンセルのチェック
    if (this.isUserCancellation(error)) {
      return 'セキュリティキーでの認証がキャンセルされました'
    }
    
    // WebAuthn固有エラーの判定
    if (error.message) {
      const message = error.message.toLowerCase()
      
      if (message.includes('timeout') || message.includes('timed out')) {
        return 'セキュリティキーの認証がタイムアウトしました。再度お試しください。'
      }
      
      if (message.includes('not allowed') || 
          message.includes('operation either timed out or was not allowed')) {
        return 'セキュリティキーでの認証が許可されませんでした。再度お試しください。'
      }
      
      if (message.includes('invalid') || message.includes('verification failed')) {
        return 'セキュリティキーの認証に失敗しました。正しいセキュリティキーを使用してください。'
      }
    }
    
    // エラー名による判定
    if (error.name === 'NotAllowedError') {
      return 'セキュリティキーでの認証が許可されませんでした。再度お試しください。'
    }
    
    if (error.name === 'AbortError') {
      return 'セキュリティキーでの認証がキャンセルされました'
    }
    
    if (error.name === 'NotSupportedError') {
      return 'このセキュリティキーはサポートされていません。'
    }
    
    // デフォルトエラーメッセージ
    return error.message || 'セキュリティキーでの認証に失敗しました'
  }

  // WebAuthn登録エラーメッセージを日本語化
  getWebAuthnErrorMessage(error) {
    console.log('Analyzing error:', error.name, error.message)
    
    // ユーザーキャンセルのチェック
    if (this.isUserCancellation(error)) {
      return 'セキュリティキーの登録がキャンセルされました'
    }
    
    // WebAuthn固有エラーの判定
    if (error.message) {
      const message = error.message.toLowerCase()
      
      if (message.includes('already registered') || 
          message.includes('contains one of the credentials already registered')) {
        return 'このセキュリティキーは既に登録されています。別のセキュリティキーを使用してください。'
      }
      
      if (message.includes('timeout') || message.includes('timed out')) {
        return 'セキュリティキーの操作がタイムアウトしました。再度お試しください。'
      }
      
      if (message.includes('not allowed') || 
          message.includes('operation either timed out or was not allowed')) {
        return 'セキュリティキーの操作が許可されませんでした。再度お試しください。'
      }
      
      if (message.includes('invalid') || message.includes('verification failed')) {
        return 'セキュリティキーの検証に失敗しました。正しいセキュリティキーを使用してください。'
      }
    }
    
    // エラー名による判定
    if (error.name === 'InvalidStateError') {
      return 'このセキュリティキーは既に登録されています。別のセキュリティキーを使用してください。'
    }
    
    if (error.name === 'NotAllowedError') {
      return 'セキュリティキーの操作が許可されませんでした。再度お試しください。'
    }
    
    if (error.name === 'AbortError') {
      return 'セキュリティキーの登録がキャンセルされました'
    }
    
    if (error.name === 'NotSupportedError') {
      return 'このセキュリティキーはサポートされていません。'
    }
    
    // デフォルトエラーメッセージ
    return error.message || 'セキュリティキーの登録に失敗しました'
  }

  // ユーザーキャンセルかどうかを判定
  isUserCancellation(error) {
    // WebAuthn仕様に基づく一般的なキャンセルエラーの判定
    const cancelMessages = [
      'The operation either timed out or was not allowed',
      'User cancelled',
      'The request has been cancelled',
      'Operation was cancelled',
      'NotAllowedError'
    ]
    
    // 重複登録エラーは別途処理するためキャンセルとしない
    const duplicateMessages = [
      'already registered',
      'contains one of the credentials already registered'
    ]
    
    const isDuplicate = duplicateMessages.some(msg => error.message?.includes(msg))
    
    return !isDuplicate && cancelMessages.some(msg => 
      error.message?.includes(msg) || 
      error.name === 'NotAllowedError' ||
      error.name === 'AbortError'
    )
  }
  
  // 名前編集モードを開始
  startEdit(event) {
    event.preventDefault()
    
    if (this.hasDisplayNameTarget && this.hasEditFormTarget && this.hasEditInputTarget) {
      this.displayNameTarget.classList.add('hidden')
      this.editFormTarget.classList.remove('hidden')
      this.editInputTarget.focus()
      this.editInputTarget.select()
    }
  }
  
  // 名前編集をキャンセル
  cancelEdit(event) {
    event.preventDefault()
    
    if (this.hasDisplayNameTarget && this.hasEditFormTarget) {
      this.editFormTarget.classList.add('hidden')
      this.displayNameTarget.classList.remove('hidden')
    }
  }
  
  // 名前を保存
  async saveEdit(event) {
    event.preventDefault()
    
    if (!this.hasEditInputTarget) return
    
    const newNickname = this.editInputTarget.value.trim()
    if (!newNickname) {
      this.showError('名前を入力してください')
      return
    }
    
    try {
      const response = await fetch(`/users/webauthn_credentials/${this.credentialIdValue}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          nickname: newNickname
        })
      })
      
      const result = await response.json()
      
      if (response.ok && result.success) {
        // 表示名を更新
        if (this.hasDisplayNameTarget) {
          this.displayNameTarget.textContent = newNickname
        }
        
        // 編集モードを終了
        this.cancelEdit(event)
        
        this.showSuccess(result.message || 'セキュリティキーの名前を変更しました')
      } else {
        throw new Error(result.error || result.message || '名前の変更に失敗しました')
      }
      
    } catch (error) {
      console.error('WebAuthn name update failed:', error)
      this.showError(error.message || 'セキュリティキーの名前変更に失敗しました')
    }
  }
}