import { Controller } from "@hotwired/stimulus"

// WebAuthn操作を管理するStimulusコントローラー
export default class extends Controller {
  static targets = ["nicknameInput", "errorMessage"]
  
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
      
      // ページをリロードして最新の状態を表示
      setTimeout(() => {
        window.location.reload()
      }, 1500)
      
    } catch (error) {
      console.error('WebAuthn registration failed:', error)
      this.showError(error.message || 'セキュリティキーの登録に失敗しました')
    }
  }
  
  // 認証を実行（ログイン時など）
  async authenticate() {
    try {
      this.hideError()
      this.showLoading("認証準備中...")
      
      // 認証用オプションを取得
      const optionsResponse = await fetch('/users/webauthn_credentials/authentication_options', {
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
      this.showError(error.message || 'セキュリティキーでの認証に失敗しました')
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
    const excludeCredentials = options.exclude_credentials?.map(cred => ({
      id: this.base64urlDecode(cred.id),
      type: cred.type
    })) || []
    
    const createOptions = {
      challenge: challenge,
      rp: options.rp,
      user: {
        id: userId,
        name: options.user.name,
        displayName: options.user.display_name
      },
      pubKeyCredParams: options.pub_key_cred_params,
      excludeCredentials: excludeCredentials,
      authenticatorSelection: options.authenticator_selection,
      timeout: options.timeout
    }
    
    console.log('Create options:', createOptions)
    
    const credential = await navigator.credentials.create({
      publicKey: createOptions
    })
    
    if (!credential) {
      throw new Error('セキュリティキーでの操作がキャンセルされました')
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
    const allowCredentials = options.allow_credentials?.map(cred => ({
      id: this.base64urlDecode(cred.id),
      type: cred.type
    })) || []
    
    const getOptions = {
      challenge: challenge,
      allowCredentials: allowCredentials,
      timeout: options.timeout,
      userVerification: options.user_verification
    }
    
    console.log('Get options:', getOptions)
    
    const credential = await navigator.credentials.get({
      publicKey: getOptions
    })
    
    if (!credential) {
      throw new Error('セキュリティキーでの操作がキャンセルされました')
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
}