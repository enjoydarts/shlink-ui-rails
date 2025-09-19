module MarkdownHelper
  require "commonmarker"

  # Markdownテキストを安全なHTMLに変換
  def markdown_to_html(text)
    return "" if text.blank?

    # CommonMarkerでHTMLに変換（XSS対策強化）
    html = Commonmarker.to_html(text, options: {
      parse: { smart: true },
      extension: {
        table: true,
        strikethrough: true,
        autolink: true,
        tagfilter: true,        # 危険なHTMLタグをフィルタ
        tasklist: true
      },
      render: {
        hardbreaks: true,
        unsafe: false           # 安全でないHTMLを無効化
      }
    })

    # 追加のHTMLサニタイズ
    sanitize_html(html).html_safe
  end

  private

  # HTMLサニタイズ（許可するタグとアトリビュートを制限）
  def sanitize_html(html)
    # 許可するHTMLタグ
    allowed_tags = %w[
      h1 h2 h3 h4 h5 h6
      p br hr
      strong b em i u del
      ul ol li
      blockquote
      a
      table thead tbody tr th td
      code pre
      input
    ]

    # 許可するアトリビュート
    allowed_attributes = {
      'a' => %w[href title],
      'input' => %w[type disabled checked],
      'th' => %w[align],
      'td' => %w[align],
      'table' => %w[],
      'thead' => %w[],
      'tbody' => %w[],
      'tr' => %w[],
    }

    # 許可するプロトコル（リンク用）
    allowed_protocols = %w[http https mailto]

    ActionController::Base.helpers.sanitize(html,
      tags: allowed_tags,
      attributes: allowed_attributes,
      protocols: allowed_protocols,
      remove_contents: %w[script style],
      whitespace_elements: {
        'pre' => :remove,
        'code' => :remove
      }
    )
  end

  # プレーンテキストの概要を生成（検索・プレビュー用）
  def markdown_to_plain_text(text, limit: 200)
    return "" if text.blank?

    # Markdownマークアップを削除
    plain = text
      .gsub(/^#+\s*/, "")        # ヘッダー記号を削除
      .gsub(/\*\*(.*?)\*\*/, '\1') # 太字マークアップを削除
      .gsub(/\*(.*?)\*/, '\1')   # 斜体マークアップを削除
      .gsub(/\[(.*?)\]\(.*?\)/, '\1') # リンクマークアップを削除
      .gsub(/`(.*?)`/, '\1')     # インラインコードを削除
      .gsub(/\n+/, " ")          # 改行をスペースに変換
      .strip

    # 指定文字数で切り詰め
    plain.length > limit ? "#{plain[0, limit]}..." : plain
  end

  # 目次を生成
  def extract_markdown_toc(text)
    return [] if text.blank?

    headers = []
    text.scan(/^(#+)\s+(.+)$/) do |level_marks, title|
      level = level_marks.length
      next if level > 6 # h6まで

      # アンカーIDを生成（日本語対応）
      anchor_id = title.downcase
        .gsub(/[^\w\s-]/, "")    # 英数字、空白、ハイフン以外を削除
        .gsub(/\s+/, "-")        # 空白をハイフンに変換
        .strip

      headers << {
        level: level,
        title: title.strip,
        anchor: anchor_id
      }
    end

    headers
  end
end
