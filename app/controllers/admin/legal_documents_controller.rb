class Admin::LegalDocumentsController < Admin::AdminController
  include MarkdownHelper

  before_action :set_document_type, only: [:show, :edit, :update]

  def index
    @documents = {
      terms_of_service: {
        title: "利用規約",
        key: "legal.terms_of_service",
        icon: "document-text",
        description: "サービスの利用条件と禁止事項を定義します"
      },
      privacy_policy: {
        title: "プライバシーポリシー",
        key: "legal.privacy_policy",
        icon: "shield-check",
        description: "個人情報の取り扱いについて説明します"
      }
    }
  end

  def show
    @setting = SystemSetting.find_by(key_name: @document_key)
    @content = @setting&.value || ""
    @page_title = @document_config[:title]
  end

  def edit
    @setting = SystemSetting.find_by(key_name: @document_key) ||
               SystemSetting.new(key_name: @document_key, setting_type: "string", category: "legal")
    @content = @setting.value || SystemSetting.load_legal_template("#{@document_type}.md")
    @page_title = "#{@document_config[:title]}を編集"
  end

  def update
    @setting = SystemSetting.find_by(key_name: @document_key)

    if @setting.nil?
      @setting = SystemSetting.new(
        key_name: @document_key,
        setting_type: "string",
        category: "legal",
        description: @document_config[:title] + "（Markdown形式で記載）"
      )
    end

    if @setting.update(value: params[:system_setting][:value])
      redirect_to admin_legal_document_path(@document_type),
                  notice: "#{@document_config[:title]}を更新しました。"
    else
      @content = params[:system_setting][:value]
      @page_title = "#{@document_config[:title]}を編集"
      flash.now[:alert] = "更新に失敗しました: #{@setting.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_document_type
    @document_type = params[:id]
    @document_config = case @document_type
    when "terms_of_service"
      { title: "利用規約", key: "legal.terms_of_service" }
    when "privacy_policy"
      { title: "プライバシーポリシー", key: "legal.privacy_policy" }
    else
      redirect_to admin_legal_documents_path, alert: "不正な文書タイプです。"
      return
    end

    @document_key = @document_config[:key]
  end

  def legal_document_params
    params.require(:system_setting).permit(:value).tap do |permitted|
      permitted[:description] = @document_config[:title] + "（Markdown形式で記載）"
    end
  end
end