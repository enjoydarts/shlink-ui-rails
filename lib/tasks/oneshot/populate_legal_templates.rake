namespace :oneshot do
  desc "Populate legal document templates (one-time setup for production)"
  task populate_legal_templates: :environment do
    puts "🔧 法的文書テンプレートの投入を開始..."

    documents = {
      "terms_of_service" => "利用規約",
      "privacy_policy" => "プライバシーポリシー"
    }

    documents.each do |doc_type, title|
      print "📄 #{title}を確認中... "

      setting = SystemSetting.find_or_create_by(
        key_name: "legal.#{doc_type}"
      ) do |s|
        s.setting_type = "string"
        s.category = "legal"
        s.description = "#{title}（Markdown形式で記載）"
      end

      if setting.value.blank?
        template_content = SystemSetting.load_legal_template("#{doc_type}.md")

        if template_content.present?
          setting.update!(value: template_content)
          puts "✅ テンプレートを投入しました (#{template_content.length}文字)"
        else
          puts "❌ テンプレートファイルが見つかりません"
        end
      else
        puts "⏭️  既に設定済みです (#{setting.value.length}文字)"
      end
    end

    puts "\n🎉 法的文書テンプレートの投入が完了しました！"
    puts "管理画面で内容を確認・編集してください: /admin/legal_documents"
  end
end
