import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "urlSelect", "searchInput", "dropdown", "noResults", "urlInfo", "chartsContainer", "loading", "noSelection", "error", "errorMessage",
    "urlTitle", "shortUrl", "longUrl", "dateCreated", "totalVisits",
    "dailyChart", "hourlyChart", "browserChart", "countryChart", "refererChart",
    "summaryTotalVisits", "summaryUniqueVisitors", "summaryAvgDaily", "summaryLastVisit"
  ]
  static values = { 
    userId: Number,
    period: String,
    urlListUrl: String,
    dataUrl: String
  }

  connect() {
    this.charts = {}
    this.urlList = []
    this.selectedUrl = null
    this.loadUrlList()
    
    // Click outside to close dropdown
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  disconnect() {
    this.destroyAllCharts()
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }

  async loadUrlList() {
    try {
      this.showLoading()
      
      const response = await fetch(this.urlListUrlValue)
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      
      const data = await response.json()
      
      if (data.success && data.urls) {
        this.urlList = data.urls
        this.populateUrlSelect(data.urls)
        this.showNoSelection()
      } else {
        throw new Error(data.error || "URL一覧の取得に失敗しました")
      }
    } catch (error) {
      console.error('URL一覧の読み込みに失敗しました:', error)
      this.showError("URL一覧の読み込みに失敗しました: " + error.message)
    }
  }

  populateUrlSelect(urls) {
    // Clear existing options except the first one
    while (this.urlSelectTarget.children.length > 1) {
      this.urlSelectTarget.removeChild(this.urlSelectTarget.lastChild)
    }

    // Add URL options
    urls.forEach(url => {
      const option = document.createElement('option')
      option.value = url.short_code
      option.textContent = `${url.title} (${url.visit_count}回)`
      option.dataset.urlData = JSON.stringify(url)
      this.urlSelectTarget.appendChild(option)
    })
  }

  async selectUrl(event) {
    const shortCode = event.target.value
    
    if (!shortCode) {
      this.showNoSelection()
      return
    }

    const selectedOption = event.target.selectedOptions[0]
    const urlData = JSON.parse(selectedOption.dataset.urlData)
    
    await this.loadIndividualData(shortCode, urlData)
  }

  async loadIndividualData(shortCode, urlData) {
    try {
      this.showLoading()
      
      // Build URL with period parameter
      const url = new URL(this.dataUrlValue.replace(':short_code', shortCode), window.location.origin)
      url.searchParams.set('period', this.periodValue)
      
      const response = await fetch(url.toString())
      
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      
      const data = await response.json()
      
      if (data.success) {
        this.displayData(data.data, urlData)
        this.showCharts()
      } else {
        throw new Error(data.error || "統計データの取得に失敗しました")
      }
    } catch (error) {
      console.error('統計データの読み込みに失敗しました:', error)
      this.showError("統計データの読み込みに失敗しました: " + error.message)
    }
  }

  displayData(data, urlData) {
    // Update URL info
    this.urlTitleTarget.textContent = urlData.title
    this.shortUrlTarget.href = urlData.short_url
    this.shortUrlTarget.textContent = urlData.short_url
    this.longUrlTarget.textContent = urlData.long_url
    this.dateCreatedTarget.textContent = urlData.date_created
    this.totalVisitsTarget.textContent = data.total_visits

    // Update summary stats
    this.summaryTotalVisitsTarget.textContent = data.total_visits
    this.summaryUniqueVisitorsTarget.textContent = data.unique_visitors
    
    // Calculate average daily visits
    const avgDaily = data.daily_visits?.values ? 
      (data.daily_visits.values.reduce((a, b) => a + b, 0) / data.daily_visits.values.length).toFixed(1) : 0
    this.summaryAvgDailyTarget.textContent = avgDaily

    // Find last visit date (last non-zero day in daily visits)
    let lastVisitDay = "なし"
    if (data.daily_visits?.labels && data.daily_visits?.values) {
      for (let i = data.daily_visits.values.length - 1; i >= 0; i--) {
        if (data.daily_visits.values[i] > 0) {
          lastVisitDay = data.daily_visits.labels[i]
          break
        }
      }
    }
    this.summaryLastVisitTarget.textContent = lastVisitDay

    // Render charts
    this.destroyAllCharts()
    this.renderDailyChart(data.daily_visits)
    this.renderHourlyChart(data.hourly_visits)
    this.renderBrowserChart(data.browser_stats)
    this.renderCountryChart(data.country_stats)
    this.renderRefererChart(data.referer_stats)
  }

  renderDailyChart(data) {
    if (!data || !data.labels || !data.values) return

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
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true },
          x: { grid: { display: false } }
        }
      }
    })
  }

  renderHourlyChart(data) {
    if (!data || !data.labels || !data.values) return

    // 既存のチャートがあれば破棄
    if (this.charts.hourly) {
      this.charts.hourly.destroy()
    }

    const ctx = this.hourlyChartTarget.getContext('2d')
    this.charts.hourly = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'アクセス数',
          data: data.values,
          backgroundColor: '#10B981',
          borderColor: '#059669',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true },
          x: { grid: { display: false } }
        }
      }
    })
  }

  renderBrowserChart(data) {
    if (!data || !data.labels || !data.values) return

    // 既存のチャートがあれば破棄
    if (this.charts.browser) {
      this.charts.browser.destroy()
    }

    const ctx = this.browserChartTarget.getContext('2d')
    this.charts.browser = new window.Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: data.labels,
        datasets: [{
          data: data.values,
          backgroundColor: [
            '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
            '#F97316', '#06B6D4', '#84CC16', '#EC4899', '#6B7280'
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: { padding: 20, usePointStyle: true }
          }
        }
      }
    })
  }

  renderCountryChart(data) {
    if (!data || !data.labels || !data.values) return

    // 既存のチャートがあれば破棄
    if (this.charts.country) {
      this.charts.country.destroy()
    }

    const ctx = this.countryChartTarget.getContext('2d')
    this.charts.country = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'アクセス数',
          data: data.values,
          backgroundColor: '#8B5CF6',
          borderColor: '#7C3AED',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        indexAxis: 'y',
        scales: {
          x: { beginAtZero: true }
        }
      }
    })
  }

  renderRefererChart(data) {
    if (!data || !data.labels || !data.values) return

    // 既存のチャートがあれば破棄
    if (this.charts.referer) {
      this.charts.referer.destroy()
    }

    const ctx = this.refererChartTarget.getContext('2d')
    this.charts.referer = new window.Chart(ctx, {
      type: 'pie',
      data: {
        labels: data.labels,
        datasets: [{
          data: data.values,
          backgroundColor: [
            '#F59E0B', '#10B981', '#3B82F6', '#EF4444', '#8B5CF6',
            '#F97316', '#06B6D4', '#84CC16', '#EC4899', '#6B7280'
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: { padding: 20, usePointStyle: true }
          }
        }
      }
    })
  }

  changePeriod(event) {
    this.periodValue = event.target.value
    
    const shortCode = this.urlSelectTarget.value
    if (shortCode) {
      const selectedOption = this.urlSelectTarget.selectedOptions[0]
      const urlData = JSON.parse(selectedOption.dataset.urlData)
      this.loadIndividualData(shortCode, urlData)
    }
  }

  retry() {
    const shortCode = this.urlSelectTarget.value
    if (shortCode) {
      const selectedOption = this.urlSelectTarget.selectedOptions[0]
      const urlData = JSON.parse(selectedOption.dataset.urlData)
      this.loadIndividualData(shortCode, urlData)
    } else {
      this.loadUrlList()
    }
  }

  // State management methods
  showLoading() {
    this.hideAllStates()
    this.loadingTarget.classList.remove('hidden')
  }

  showNoSelection() {
    this.hideAllStates()
    this.noSelectionTarget.classList.remove('hidden')
  }

  showCharts() {
    this.hideAllStates()
    this.urlInfoTarget.classList.remove('hidden')
    this.chartsContainerTarget.classList.remove('hidden')
  }

  showError(message) {
    this.hideAllStates()
    this.errorMessageTarget.textContent = message
    this.errorTarget.classList.remove('hidden')
  }

  hideAllStates() {
    [this.loadingTarget, this.noSelectionTarget, this.errorTarget, 
     this.urlInfoTarget, this.chartsContainerTarget].forEach(target => {
      target.classList.add('hidden')
    })
  }

  destroyAllCharts() {
    Object.values(this.charts).forEach(chart => {
      if (chart) chart.destroy()
    })
    this.charts = {}
  }

  // Search functionality
  searchUrls(event) {
    const query = event.target.value.toLowerCase().trim()
    
    if (query === '') {
      this.hideDropdown()
      return
    }

    const filteredUrls = this.urlList.filter(url => {
      return url.title.toLowerCase().includes(query) ||
             url.short_url.toLowerCase().includes(query) ||
             url.short_code.toLowerCase().includes(query) ||
             url.long_url.toLowerCase().includes(query)
    })

    this.renderDropdown(filteredUrls)
  }

  showDropdown() {
    if (this.urlList.length > 0) {
      this.renderDropdown(this.urlList)
    }
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
  }

  renderDropdown(urls) {
    const dropdown = this.dropdownTarget
    
    // Clear existing items
    dropdown.innerHTML = ''
    
    if (urls.length === 0) {
      const noResultsDiv = document.createElement('div')
      noResultsDiv.className = 'p-2 text-sm text-gray-500 text-center'
      noResultsDiv.textContent = '検索結果がありません'
      dropdown.appendChild(noResultsDiv)
    } else {
      urls.forEach(url => {
        const item = document.createElement('div')
        item.className = 'px-3 py-2 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-b-0'
        item.dataset.shortCode = url.short_code
        item.dataset.urlData = JSON.stringify(url)
        
        item.innerHTML = `
          <div class="flex justify-between items-center">
            <div class="flex-1 min-w-0">
              <div class="text-sm font-medium text-gray-900 truncate">${url.title}</div>
              <div class="text-xs text-gray-500 truncate">${url.short_url}</div>
            </div>
            <div class="text-xs text-gray-400 ml-2">${url.visit_count}回</div>
          </div>
        `
        
        item.addEventListener('click', (e) => {
          e.stopPropagation()
          this.selectUrlFromDropdown(url)
        })
        
        dropdown.appendChild(item)
      })
    }
    
    dropdown.classList.remove('hidden')
  }

  selectUrlFromDropdown(urlData) {
    this.selectedUrl = urlData
    this.searchInputTarget.value = urlData.title
    this.hideDropdown()
    
    // Update hidden select for compatibility
    this.urlSelectTarget.value = urlData.short_code
    const option = Array.from(this.urlSelectTarget.options).find(opt => opt.value === urlData.short_code)
    if (!option) {
      const newOption = document.createElement('option')
      newOption.value = urlData.short_code
      newOption.dataset.urlData = JSON.stringify(urlData)
      this.urlSelectTarget.appendChild(newOption)
    }
    
    this.loadIndividualData(urlData.short_code, urlData)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }
}