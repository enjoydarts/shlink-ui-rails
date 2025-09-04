// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Register controllers manually
import SubmitterController from "controllers/submitter_controller"
import ClipboardController from "controllers/clipboard_controller"

application.register("submitter", SubmitterController)
application.register("clipboard", ClipboardController)

eagerLoadControllersFrom("controllers", application)
