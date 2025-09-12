import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleSubmitEnd(event) {
    // フォーム送信後にセキュリティタブに確実に切り替える
    setTimeout(() => {
      // URLハッシュを強制設定
      if (window.location.pathname.includes('/account')) {
        window.location.hash = 'security'
        
        // account-tabsコントローラーを直接操作
        const tabsElement = document.querySelector('[data-controller*="account-tabs"]')
        if (tabsElement && tabsElement.accountTabs) {
          tabsElement.accountTabs.activateTab('security')
        }
        
        // または直接タブを切り替え
        this.forceSecurityTab()
      }
    }, 100)
  }
  
  forceSecurityTab() {
    // セキュリティタブボタンを見つけてクリック
    const securityTabButton = document.querySelector('[data-tab="security"]')
    if (securityTabButton) {
      securityTabButton.click()
    }
  }
}