class LegalController < ApplicationController
  include MarkdownHelper

  # 利用規約表示
  def terms_of_service
    @content = SystemSetting.get("legal.terms_of_service", default_terms_content)
    @page_title = "利用規約"
  end

  # プライバシーポリシー表示
  def privacy_policy
    @content = SystemSetting.get("legal.privacy_policy", default_privacy_content)
    @page_title = "プライバシーポリシー"
  end

  private

  def default_terms_content
    SystemSetting.load_legal_template("terms_of_service.md")
  end

  def default_privacy_content
    SystemSetting.load_legal_template("privacy_policy.md")
  end
end
