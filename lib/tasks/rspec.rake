begin
  require 'rspec/core/rake_task'
  
  RSpec::Core::RakeTask.new(:spec)
  
  # 詳細な出力でテスト実行
  RSpec::Core::RakeTask.new(:spec_detailed) do |t|
    t.rspec_opts = '--format documentation --color'
  end
  
  # プログレス形式でテスト実行
  RSpec::Core::RakeTask.new(:spec_progress) do |t|
    t.rspec_opts = '--format progress --color'
  end
  
  # 失敗したテストのみ再実行
  RSpec::Core::RakeTask.new(:spec_failed) do |t|
    t.rspec_opts = '--only-failures --format documentation --color'
  end
  
  task default: :spec
rescue LoadError
  # RSpec is not available
end