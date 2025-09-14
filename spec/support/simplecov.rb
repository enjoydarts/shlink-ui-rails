require "simplecov"

SimpleCov.start "rails" do
  # カバレッジを計測しないディレクトリ
  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/vendor/"

  # カバレッジを計測するディレクトリ
  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Forms", "app/forms"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Helpers", "app/helpers"

  # 最小カバレッジ率
  minimum_coverage 70
end
