import { Controller } from "@hotwired/stimulus"

// アカウント設定画面のタブナビゲーションを管理するController
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { 
    active: { type: String, default: "basic" }
  }

  connect() {
    // 初期化時にアクティブなタブを設定
    this.showTab(this.activeValue)
  }

  // タブクリック時の処理
  switchTab(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
    this.activeValue = tabName
  }

  // キーボードナビゲーション対応
  keydown(event) {
    const tabs = this.tabTargets
    const currentIndex = tabs.findIndex(tab => tab.classList.contains("active"))
    
    let nextIndex = currentIndex
    
    switch (event.key) {
      case "ArrowLeft":
        event.preventDefault()
        nextIndex = currentIndex > 0 ? currentIndex - 1 : tabs.length - 1
        break
      case "ArrowRight":
        event.preventDefault()
        nextIndex = currentIndex < tabs.length - 1 ? currentIndex + 1 : 0
        break
      case "Home":
        event.preventDefault()
        nextIndex = 0
        break
      case "End":
        event.preventDefault()
        nextIndex = tabs.length - 1
        break
      default:
        return
    }
    
    const nextTab = tabs[nextIndex]
    const tabName = nextTab.dataset.tab
    this.showTab(tabName)
    this.activeValue = tabName
    nextTab.focus()
  }

  // 指定されたタブを表示する
  showTab(tabName) {
    // 全てのタブとパネルを非アクティブ化
    this.tabTargets.forEach(tab => {
      tab.classList.remove("active", "bg-white", "text-blue-600", "shadow-sm")
      tab.classList.add("text-gray-600", "hover:text-blue-600", "hover:bg-white/50")
      tab.setAttribute("aria-selected", "false")
      tab.setAttribute("tabindex", "-1")
    })

    this.panelTargets.forEach(panel => {
      panel.classList.add("hidden")
      panel.setAttribute("aria-hidden", "true")
    })

    // アクティブなタブとパネルを表示
    const activeTab = this.tabTargets.find(tab => tab.dataset.tab === tabName)
    const activePanel = this.panelTargets.find(panel => panel.dataset.panel === tabName)

    if (activeTab && activePanel) {
      // タブのスタイリング
      activeTab.classList.add("active", "bg-white", "text-blue-600", "shadow-sm")
      activeTab.classList.remove("text-gray-600", "hover:text-blue-600", "hover:bg-white/50")
      activeTab.setAttribute("aria-selected", "true")
      activeTab.setAttribute("tabindex", "0")

      // パネルの表示
      activePanel.classList.remove("hidden")
      activePanel.setAttribute("aria-hidden", "false")

      // フェードインアニメーション
      this.animatePanel(activePanel)
    }
  }

  // パネルのフェードインアニメーション
  animatePanel(panel) {
    panel.style.opacity = "0"
    panel.style.transform = "translateY(10px)"
    panel.style.transition = "all 0.3s cubic-bezier(0.16, 1, 0.3, 1)"

    requestAnimationFrame(() => {
      panel.style.opacity = "1"
      panel.style.transform = "translateY(0)"
    })
  }

  // 外部からタブを切り替えるためのメソッド
  activateTab(tabName) {
    this.showTab(tabName)
    this.activeValue = tabName
  }
}