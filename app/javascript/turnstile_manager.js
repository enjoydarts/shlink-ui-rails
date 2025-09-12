// Turnstile管理用の外部JavaScript
window.SimpleTurnstile = window.SimpleTurnstile || {
  widgetId: null,
  isReady: false,
  
  // コールバック関数を一度だけ設定
  setupCallbacks: function() {
    // onTurnstileLoadは既にHTMLで定義されている場合があるのでスキップ
    
    window.onTurnstileSuccess = function(token) {
      // トークンを hidden input に設定
      const tokenInput = document.querySelector('input[name="cf_turnstile_response"], #turnstile-token, #turnstile-token-reg');
      if (tokenInput) {
        tokenInput.value = token;
      }
      
      // エラー表示を隠す
      const errorDiv = document.getElementById('turnstile-error');
      if (errorDiv) errorDiv.classList.add('hidden');
      
      // Turnstile検証完了フラグを設定
      window.turnstileVerified = true;
      
      // 送信ボタンを有効化
      const submitButton = document.querySelector('button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = false;
        submitButton.classList.remove('opacity-50', 'cursor-not-allowed');
        submitButton.setAttribute('data-turnstile-verified', 'true');
      }
    };
    
    window.onTurnstileError = function() {
      SimpleTurnstile.showError('セキュリティ検証でエラーが発生しました。ページを再読み込みしてください。');
    };
    
    window.onTurnstileExpired = function() {
      SimpleTurnstile.showError('セキュリティ検証の有効期限が切れました。');
      SimpleTurnstile.reset();
    };
  },
  
  showError: function(message) {
    const errorDiv = document.getElementById('turnstile-error');
    const errorMessage = document.getElementById('turnstile-error-message');
    
    if (errorDiv && errorMessage) {
      errorMessage.textContent = message;
      errorDiv.classList.remove('hidden');
    }
    
    // Turnstile検証状態をリセット
    window.turnstileVerified = false;
    
    // 送信ボタンを無効化
    const submitButton = document.querySelector('button[type="submit"]');
    if (submitButton) {
      submitButton.disabled = true;
      submitButton.classList.add('opacity-50', 'cursor-not-allowed');
      submitButton.removeAttribute('data-turnstile-verified');
    }
  },
  
  reset: function() {
    if (this.widgetId !== null && window.turnstile && window.turnstile.reset) {
      try {
        window.turnstile.reset(this.widgetId);
      } catch (e) {
        console.log('Reset failed, will reinitialize:', e);
        this.clean();
        this.renderWidget();
      }
    }
  },
  
  clean: function() {
    if (this.widgetId !== null && window.turnstile && window.turnstile.remove) {
      try {
        window.turnstile.remove(this.widgetId);
      } catch (e) {
        console.log('Remove failed:', e);
      }
    }
    this.widgetId = null;
    
    const container = document.getElementById('turnstile-container');
    if (container) {
      container.innerHTML = '';
    }
  },
  
  renderWidget: function() {
    const container = document.getElementById('turnstile-container');
    if (!container) return;
    
    // 既に存在する場合はスキップ
    if (this.widgetId !== null) return;
    
    // Turnstile APIが利用可能かチェック
    if (!window.turnstile || !window.turnstile.render) {
      setTimeout(() => this.renderWidget(), 500);
      return;
    }
    
    // コンテナをクリア
    container.innerHTML = '';
    
    try {
      // siteKeyを動的に取得
      const siteKey = container.dataset.sitekey || '';
      if (!siteKey) return;
      
      this.widgetId = window.turnstile.render(container, {
        sitekey: siteKey,
        callback: window.onTurnstileSuccess,
        'error-callback': window.onTurnstileError,
        'expired-callback': window.onTurnstileExpired
      });
      
      // 初期状態として送信ボタンを無効化
      const submitButton = document.querySelector('button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = true;
        submitButton.classList.add('opacity-50', 'cursor-not-allowed');
      }
      
    } catch (e) {
      console.error('Turnstile render failed:', e);
    }
  },
  
  init: function() {
    this.setupCallbacks();
    
    // Turnstile APIが既に読み込まれている場合
    if (window.turnstile && window.turnstile.render) {
      this.isReady = true;
      this.renderWidget();
    }
    // APIの読み込みを待つ場合は onTurnstileLoad で処理される
  }
};

// DOM準備完了時に初期化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', SimpleTurnstile.init.bind(SimpleTurnstile));
} else {
  SimpleTurnstile.init();
}

// Turbo イベント対応
document.addEventListener('turbo:load', function() {
  SimpleTurnstile.clean();
  setTimeout(function() {
    SimpleTurnstile.init();
  }, 100);
});

document.addEventListener('turbo:before-cache', function() {
  SimpleTurnstile.clean();
});