module ApplicationHelper
  def nav_link_class(page)
    current_page = case
    when request.path.include?("/mypage")
                     "mypage"
    when request.path.include?("/dashboard") || request.path == "/" || request.path.include?("/short_urls")
                     "dashboard"
    else
                     nil
    end

    # Tailwindが認識できるように完全なクラス名を定義
    base_classes = "inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
    active_classes = "bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm"
    inactive_classes = "text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-white/50 dark:hover:bg-gray-700/50"

    if current_page == page
      "#{base_classes} #{active_classes}"
    else
      "#{base_classes} #{inactive_classes}"
    end
  end

  # 統一されたエラーメッセージ表示
  def render_form_errors(resource_or_errors)
    errors = resource_or_errors.respond_to?(:errors) ? resource_or_errors.errors : resource_or_errors
    render "shared/form_errors", errors: errors if errors.any?
  end

  # 統一されたフィールドエラー表示
  def render_field_error(field_errors)
    render "shared/field_error", errors: field_errors if field_errors.any?
  end

  # 統一されたフラッシュメッセージ表示
  def render_flash_messages
    render "shared/flash_messages" if flash.any?
  end

  # テーマ設定関連のヘルパーメソッド

  # 現在のユーザーのテーマ設定を取得
  def current_theme
    return "system" unless user_signed_in?

    current_user.theme_preference || "system"
  end

  # HTMLクラスにテーマ情報を追加
  def body_theme_class
    theme = current_theme
    classes = []

    case theme
    when "dark"
      classes << "dark"
    when "light"
      # ライトモードの場合は特別なクラスは不要
    when "system"
      # システム設定の場合もサーバーサイドで判定してみる
      # JavaScriptでも後から制御するが、初期状態でダークの可能性があれば設定
      classes << "system-theme"
    end

    classes.join(" ")
  end

  # テーマコントローラー用のデータ属性
  def theme_controller_data
    return {} unless user_signed_in?

    {
      controller: "theme",
      theme_current_value: current_theme,
      theme_system_value: (current_theme == "system").to_s
    }
  end

  # テーマ切り替えボタン用のヘルパー
  def theme_toggle_button(options = {})
    return unless user_signed_in?

    default_options = {
      class: "inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-colors duration-200 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300",
      data: {
        action: "click->theme#toggle",
        theme_target: "toggle"
      }
    }

    merged_options = default_options.deep_merge(options)

    content_tag(:button, merged_options) do
      concat content_tag(:span, get_theme_icon(current_theme), data: { theme_icon: true })
      concat " "
      concat content_tag(:span, get_theme_display_name(current_theme), data: { theme_text: true })
    end
  end

  private

  # テーマアイコンを取得
  def get_theme_icon(theme)
    case theme
    when "light"
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12,8A4,4 0 0,0 8,12A4,4 0 0,0 12,16A4,4 0 0,0 16,12A4,4 0 0,0 12,8M12,18A6,6 0 0,1 6,12A6,6 0 0,1 12,6A6,6 0 0,1 18,12A6,6 0 0,1 12,18M20,8.69V4H15.31L12,0.69L8.69,4H4V8.69L0.69,12L4,15.31V20H8.69L12,23.31L15.31,20H20V15.31L23.31,12L20,8.69Z"/></svg>'.html_safe
    when "dark"
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.75,4.09L15.22,6.03L16.13,9.09L13.5,7.28L10.87,9.09L11.78,6.03L9.25,4.09L12.44,4L13.5,1L14.56,4L17.75,4.09M21.25,11L19.61,12.25L20.2,14.23L18.5,13.06L16.8,14.23L17.39,12.25L15.75,11L17.81,10.95L18.5,9L19.19,10.95L21.25,11M18.97,15.95C19.8,15.87 20.69,17.05 20.16,17.8C19.84,18.25 19.5,18.67 19.08,19.07C15.17,23 8.84,23 4.94,19.07C1.03,15.17 1.03,8.83 4.94,4.93C5.34,4.53 5.76,4.17 6.21,3.85C6.96,3.32 8.14,4.21 8.06,5.04C7.79,7.9 8.75,10.87 10.95,13.06C13.14,15.26 16.1,16.22 18.97,15.95M17.33,17.97C14.5,17.81 11.7,16.64 9.53,14.5C7.36,12.31 6.2,9.5 6.04,6.68C3.23,9.82 3.34,14.4 6.35,17.41C9.37,20.43 14,20.54 17.33,17.97Z"/></svg>'.html_safe
    else
      '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M4,6H20V16H4M20,18A2,2 0 0,0 22,16V6C22,4.89 21.1,4 20,4H4C2.89,4 2,4.89 2,6V16A2,2 0 0,0 4,18H0V20H24V20H20Z"/></svg>'.html_safe
    end
  end

  # テーマ表示名を取得
  def get_theme_display_name(theme)
    case theme
    when "light"
      "ライト"
    when "dark"
      "ダーク"
    else
      "システム"
    end
  end
end
