import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overallChart", "dailyChart", "statusChart", "monthlyChart"]
  static values = { 
    userId: Number,
    period: String,
    dataUrl: String 
  }

  connect() {
    this.charts = {}
    this.loadStatisticsData()
  }

  disconnect() {
    // Clean up charts when controller disconnects
    this.destroyAllCharts()
  }

  async loadStatisticsData() {
    try {
      this.showLoadingState()
      
      // 期間パラメータをURLに追加
      const url = new URL(this.dataUrlValue, window.location.origin)
      url.searchParams.set('period', this.periodValue)
      
      const response = await fetch(url.toString())
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      
      const data = await response.json()
      this.renderCharts(data)
      this.hideLoadingState()
    } catch (error) {
      console.error('統計データの読み込みに失敗しました:', error)
      this.hideLoadingState()
      this.showErrorState()
    }
  }

  renderCharts(response) {
    // APIレスポンスの構造: { success: true, data: { overall, daily, status, monthly } }
    const data = response.data || response
    
    // 全体統計ドーナツチャート
    if (this.hasOverallChartTarget && data.overall) {
      this.renderOverallChart(data.overall)
    }

    // 日別アクセス推移線グラフ
    if (this.hasDailyChartTarget && data.daily) {
      this.renderDailyChart(data.daily)
    }

    // URL状態分布円グラフ  
    if (this.hasStatusChartTarget && data.status) {
      this.renderStatusChart(data.status)
    }

    // 月別作成数棒グラフ
    if (this.hasMonthlyChartTarget && data.monthly) {
      this.renderMonthlyChart(data.monthly)
    }
  }

  renderOverallChart(data) {
    if (!data || typeof data.total_urls === 'undefined') {
      console.error('Invalid overall chart data:', data)
      return
    }
    
    // 既存のチャートがあれば破棄
    if (this.charts.overall) {
      this.charts.overall.destroy()
    }
    
    const ctx = this.overallChartTarget.getContext('2d')
    
    this.charts.overall = new window.Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['総URL数', '総アクセス数', '有効URL数'],
        datasets: [{
          data: [data.total_urls, data.total_visits, data.active_urls],
          backgroundColor: [
            '#3B82F6', // Blue
            '#10B981', // Green  
            '#8B5CF6'  // Purple
          ],
          borderWidth: 2,
          borderColor: '#FFFFFF'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 20,
              usePointStyle: true
            }
          },
          title: {
            display: true,
            text: '全体統計サマリー',
            font: { size: 16, weight: 'bold' }
          }
        }
      }
    })
  }

  renderDailyChart(data) {
    // 既存のチャートがあれば破棄
    if (this.charts.daily) {
      this.charts.daily.destroy()
    }
    
    const ctx = this.dailyChartTarget.getContext('2d')
    
    this.charts.daily = new window.Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'アクセス数',
          data: data.values,
          borderColor: '#3B82F6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 2,
          fill: true,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: '日別アクセス推移',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  renderStatusChart(data) {
    // 既存のチャートがあれば破棄
    if (this.charts.status) {
      this.charts.status.destroy()
    }
    
    const ctx = this.statusChartTarget.getContext('2d')
    
    this.charts.status = new window.Chart(ctx, {
      type: 'pie',
      data: {
        labels: data.labels,
        datasets: [{
          data: data.values,
          backgroundColor: [
            '#10B981', // Active - Green
            '#F59E0B', // Expired - Yellow
            '#EF4444', // Limit reached - Red
            '#6B7280'  // Others - Gray
          ],
          borderWidth: 2,
          borderColor: '#FFFFFF'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: 'URL状態分布',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            position: 'bottom',
            labels: {
              padding: 20,
              usePointStyle: true
            }
          }
        }
      }
    })
  }

  renderMonthlyChart(data) {
    // 既存のチャートがあれば破棄
    if (this.charts.monthly) {
      this.charts.monthly.destroy()
    }
    
    const ctx = this.monthlyChartTarget.getContext('2d')
    
    this.charts.monthly = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.labels,
        datasets: [{
          label: '作成数',
          data: data.values,
          backgroundColor: '#8B5CF6',
          borderColor: '#7C3AED',
          borderWidth: 1,
          borderRadius: 8,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: '月別URL作成数',
            font: { size: 16, weight: 'bold' }
          },
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  showErrorState() {
    // Show error message in chart containers
    const targets = [
      this.overallChartTarget,
      this.dailyChartTarget, 
      this.statusChartTarget,
      this.monthlyChartTarget
    ].filter(target => target)

    targets.forEach(target => {
      target.innerHTML = `
        <div class="flex items-center justify-center h-full text-gray-500">
          <div class="text-center">
            <svg class="w-12 h-12 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <p class="text-sm">統計データの読み込みに失敗しました</p>
          </div>
        </div>
      `
    })
  }

  // Period filter change handler
  changePeriod(event) {
    this.periodValue = event.target.value
    // 既存のチャートを全て破棄してからリロード
    this.destroyAllCharts()
    this.loadStatisticsData()
  }

  // 全てのチャートを破棄するヘルパーメソッド
  destroyAllCharts() {
    Object.values(this.charts).forEach(chart => {
      if (chart) chart.destroy()
    })
    this.charts = {}
  }

  // ローディング状態表示
  showLoadingState() {
    // 全てのチャートコンテナにローディング表示
    const chartTargets = [
      this.overallChartTarget,
      this.dailyChartTarget, 
      this.statusChartTarget,
      this.monthlyChartTarget
    ].filter(target => target)

    chartTargets.forEach(target => {
      const canvas = target
      const container = canvas.parentElement
      
      // 既存のローディング要素があれば削除
      const existingLoader = container.querySelector('.chart-loading')
      if (existingLoader) existingLoader.remove()
      
      // キャンバスを非表示
      canvas.style.display = 'none'
      
      // ローディング要素を作成
      const loader = document.createElement('div')
      loader.className = 'chart-loading flex items-center justify-center h-full'
      loader.innerHTML = `
        <div class="text-center">
          <svg class="animate-spin h-8 w-8 text-blue-500 mx-auto mb-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="text-sm text-gray-500">読み込み中...</p>
        </div>
      `
      container.appendChild(loader)
    })
  }

  // ローディング状態非表示
  hideLoadingState() {
    // 全てのローディング要素を削除
    const loaders = document.querySelectorAll('.chart-loading')
    loaders.forEach(loader => loader.remove())
    
    // キャンバスを表示
    const chartTargets = [
      this.overallChartTarget,
      this.dailyChartTarget, 
      this.statusChartTarget,
      this.monthlyChartTarget
    ].filter(target => target)

    chartTargets.forEach(target => {
      target.style.display = 'block'
    })
  }
}