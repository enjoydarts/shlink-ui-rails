# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AsyncDeviseMailer, type: :mailer do
  include ActiveJob::TestHelper
  
  let(:user) { create(:user) }
  let(:token) { 'test-token' }
  let(:opts) { {} }

  describe 'mailer methods' do
    it 'confirmation_instructionsメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:confirmation_instructions)
    end

    it 'reset_password_instructionsメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:reset_password_instructions)
    end

    it 'unlock_instructionsメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:unlock_instructions)
    end

    it 'email_changedメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:email_changed)
    end

    it 'password_changeメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:password_change)
    end
  end
end