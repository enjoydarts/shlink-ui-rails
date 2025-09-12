# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MailAdapter::BaseAdapter do
  let(:adapter) { described_class.new }

  describe 'Error class' do
    it 'StandardErrorを継承していること' do
      expect(MailAdapter::BaseAdapter::Error.superclass).to eq(StandardError)
    end

    it 'original_errorを保持すること' do
      original = StandardError.new('original')
      error = MailAdapter::BaseAdapter::Error.new('test message', original)
      expect(error.original_error).to eq(original)
    end
  end

  describe '#initialize' do
    it 'NotImplementedErrorを発生させること' do
      expect {
        described_class.new
      }.to raise_error(NotImplementedError, "MailAdapter::BaseAdapter#initialize must be implemented")
    end
  end

  describe 'abstract methods' do
    let(:concrete_adapter) do
      Class.new(described_class) do
        def initialize
          # concrete implementation
        end
      end.new
    end

    describe '#deliver_mail' do
      it 'NotImplementedErrorを発生させること' do
        expect {
          concrete_adapter.deliver_mail(nil)
        }.to raise_error(NotImplementedError, /deliver_mail must be implemented/)
      end
    end

    describe '#available?' do
      it 'NotImplementedErrorを発生させること' do
        expect {
          concrete_adapter.available?
        }.to raise_error(NotImplementedError, /available\? must be implemented/)
      end
    end

    describe '#configured?' do
      it 'NotImplementedErrorを発生させること' do
        expect {
          concrete_adapter.configured?
        }.to raise_error(NotImplementedError, /configured\? must be implemented/)
      end
    end
  end

  describe 'logging methods' do
    let(:concrete_adapter) do
      Class.new(described_class) do
        def initialize
          # concrete implementation
        end

        def test_log_info(message)
          log_info(message)
        end

        def test_log_error(message, error = nil)
          log_error(message, error)
        end
      end.new
    end

    describe '#log_info' do
      it 'Rails.loggerにinfo レベルでログ出力すること' do
        expect(Rails.logger).to receive(:info).with(/test message/)
        concrete_adapter.test_log_info('test message')
      end
    end

    describe '#log_error' do
      context 'エラーオブジェクトが渡された場合' do
        let(:error) { StandardError.new('test error') }

        before do
          allow(error).to receive(:backtrace).and_return(['line1', 'line2'])
        end

        it 'Rails.loggerにerrorレベルでログ出力すること' do
          expect(Rails.logger).to receive(:error).with(/test message: test error/)
          expect(Rails.logger).to receive(:error).with("line1\nline2")
          concrete_adapter.test_log_error('test message', error)
        end
      end

      context 'エラーオブジェクトが渡されない場合' do
        it 'Rails.loggerにerrorレベルでメッセージのみログ出力すること' do
          expect(Rails.logger).to receive(:error).with(/test message/)
          concrete_adapter.test_log_error('test message')
        end
      end
    end
  end
end