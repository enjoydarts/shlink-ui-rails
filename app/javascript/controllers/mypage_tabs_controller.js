import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "content"]
  static values = { activeTab: String }

  connect() {
    this.activeTabValue = "urls" // デフォルトはURL一覧
    this.updateTabs()
  }

  switchTab(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tab
    
    if (tabName === this.activeTabValue) return // 既にアクティブなタブ
    
    this.activeTabValue = tabName
    this.updateTabs()
    
    // 統計タブに切り替えた時にグラフを再読み込み
    if (tabName === "statistics") {
      this.loadStatistics()
    }
    
    // 個別分析タブに切り替えた時にURL一覧を再読み込み
    if (tabName === "individual") {
      this.loadIndividualAnalysis()
    }
  }

  updateTabs() {
    // すべてのタブボタンを非アクティブ状態にリセット
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === this.activeTabValue
      
      if (isActive) {
        // アクティブタブのスタイリング
        tab.classList.remove("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        tab.classList.add("border-blue-500", "text-blue-600")
        tab.setAttribute("aria-selected", "true")
      } else {
        // 非アクティブタブのスタイリング
        tab.classList.remove("border-blue-500", "text-blue-600")
        tab.classList.add("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        tab.setAttribute("aria-selected", "false")
      }
    })

    // パネルの表示切り替え
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.tab === this.activeTabValue
      
      if (isActive) {
        panel.classList.remove("hidden")
        panel.style.display = "block" // 強制的に表示
        panel.setAttribute("aria-hidden", "false")
      } else {
        panel.classList.add("hidden")
        panel.style.display = "none" // 強制的に非表示
        panel.setAttribute("aria-hidden", "true")
      }
    })
  }

  loadStatistics() {
    // 統計グラフコントローラーに統計データの読み込みを依頼
    const statisticsController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="statistics-charts"]'),
      "statistics-charts"
    )
    
    if (statisticsController) {
      statisticsController.loadStatisticsData()
    }
  }

  loadIndividualAnalysis() {
    // 個別分析コントローラーにURL一覧の読み込みを依頼
    const individualController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="individual-analysis"]'),
      "individual-analysis"
    )
    
    if (individualController) {
      individualController.loadUrlList()
    }
  }

  // キーボードナビゲーション対応
  keydown(event) {
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      event.preventDefault()
      
      const currentIndex = this.tabTargets.findIndex(tab => tab.dataset.tab === this.activeTabValue)
      let nextIndex
      
      if (event.key === "ArrowLeft") {
        nextIndex = currentIndex > 0 ? currentIndex - 1 : this.tabTargets.length - 1
      } else {
        nextIndex = currentIndex < this.tabTargets.length - 1 ? currentIndex + 1 : 0
      }
      
      const nextTab = this.tabTargets[nextIndex]
      this.activeTabValue = nextTab.dataset.tab
      this.updateTabs()
      nextTab.focus()
    }
  }
}