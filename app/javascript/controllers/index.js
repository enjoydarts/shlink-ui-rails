// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Register controllers manually
import SubmitterController from "controllers/submitter_controller"
import ClipboardController from "controllers/clipboard_controller"
import MypageTabsController from "controllers/mypage_tabs_controller"
import StatisticsChartsController from "controllers/statistics_charts_controller"
import IndividualAnalysisController from "controllers/individual_analysis_controller"

application.register("submitter", SubmitterController)
application.register("clipboard", ClipboardController)
application.register("mypage-tabs", MypageTabsController)
application.register("statistics-charts", StatisticsChartsController)
application.register("individual-analysis", IndividualAnalysisController)

eagerLoadControllersFrom("controllers", application)
