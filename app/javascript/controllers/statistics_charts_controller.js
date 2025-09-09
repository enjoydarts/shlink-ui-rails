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
    Object.values(this.charts).forEach(chart => {
      if (chart) chart.destroy()
    })
    this.charts = {}
  }

  async loadStatisticsData() {
    try {
      const response = await fetch(this.dataUrlValue)
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      
      const data = await response.json()
      this.renderCharts(data)
    } catch (error) {
      console.error('統計データの読み込みに失敗しました:', error)
      this.showErrorState()
    }
  }

  renderCharts(data) {
    // 全体統計ドーナツチャート
    if (this.hasOverallChartTarget) {
      this.renderOverallChart(data.overall)
    }

    // 日別アクセス推移線グラフ
    if (this.hasDailyChartTarget) {
      this.renderDailyChart(data.daily)
    }

    // URL状態分布円グラフ  
    if (this.hasStatusChartTarget) {
      this.renderStatusChart(data.status)
    }

    // 月別作成数棒グラフ
    if (this.hasMonthlyChartTarget) {
      this.renderMonthlyChart(data.monthly)
    }
  }

  renderOverallChart(data) {
    const ctx = this.overallChartTarget.getContext('2d')
    
    this.charts.overall = new Chart(ctx, {
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
    const ctx = this.dailyChartTarget.getContext('2d')
    
    this.charts.daily = new Chart(ctx, {
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
    const ctx = this.statusChartTarget.getContext('2d')
    
    this.charts.status = new Chart(ctx, {
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
    const ctx = this.monthlyChartTarget.getContext('2d')
    
    this.charts.monthly = new Chart(ctx, {
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
    this.loadStatisticsData()
  }
}