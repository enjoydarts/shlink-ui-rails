# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe '#default_from_address' do
    let(:mailer_instance) { described_class.new }

    context '開発・テスト環境' do
      it 'デフォルトの送信者アドレスを返すこと' do
        result = mailer_instance.send(:default_from_address)
        expect(result).to eq('from@example.com')
      end
    end

    context 'エラーが発生した場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(Settings).to receive(:mail_delivery_method).and_raise(StandardError.new('設定エラー'))
      end

      it 'フォールバックアドレスを返すこと' do
        expect(Rails.logger).to receive(:error).with(/送信者アドレス取得中にエラーが発生/)
        result = mailer_instance.send(:default_from_address)
        expect(result).to eq('from@example.com')
      end
    end
  end

  describe 'class configuration' do
    it 'ActionMailer::Baseを継承していること' do
      expect(described_class.superclass).to eq(ActionMailer::Base)
    end
  end
end
