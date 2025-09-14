class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # 統一設定システムをモデルでも使用可能にする
  include ConfigShortcuts
end
