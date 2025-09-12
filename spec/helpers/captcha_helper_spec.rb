# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaptchaHelper, type: :helper do
  describe '.enabled?' do
    context 'when CAPTCHA is configured and not in test environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('test_site_key')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('test_secret_key')
      end

      it 'returns true' do
        expect(CaptchaHelper.enabled?).to be true
      end
    end

    context 'when in test environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
      end

      it 'returns false' do
        expect(CaptchaHelper.enabled?).to be false
      end
    end

    context 'when site_key is blank' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('test_secret_key')
      end

      it 'returns false' do
        expect(CaptchaHelper.enabled?).to be false
      end
    end

    context 'when secret_key is blank' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('test_site_key')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('')
      end

      it 'returns false' do
        expect(CaptchaHelper.enabled?).to be false
      end
    end
  end

  describe '.disabled?' do
    context 'when in test environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
      end

      it 'returns true' do
        expect(CaptchaHelper.disabled?).to be true
      end
    end

    context 'when keys are missing' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('test_secret_key')
      end

      it 'returns true' do
        expect(CaptchaHelper.disabled?).to be true
      end
    end

    context 'when properly configured and not in test environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('test_site_key')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('test_secret_key')
      end

      it 'returns false' do
        expect(CaptchaHelper.disabled?).to be false
      end
    end
  end

  describe '.configured?' do
    context 'when both keys are present' do
      before do
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('test_site_key')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('test_secret_key')
      end

      it 'returns true' do
        expect(CaptchaHelper.configured?).to be true
      end
    end

    context 'when site_key is missing' do
      before do
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return(nil)
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return('test_secret_key')
      end

      it 'returns false' do
        expect(CaptchaHelper.configured?).to be false
      end
    end

    context 'when secret_key is missing' do
      before do
        allow(Settings.captcha.turnstile).to receive(:site_key).and_return('test_site_key')
        allow(Settings.captcha.turnstile).to receive(:secret_key).and_return(nil)
      end

      it 'returns false' do
        expect(CaptchaHelper.configured?).to be false
      end
    end
  end

  describe '.required_for?' do
    let(:sessions_controller) { instance_double('Users::SessionsController') }
    let(:registrations_controller) { instance_double('Users::RegistrationsController') }
    let(:other_controller) { instance_double('ApplicationController') }

    before do
      allow(sessions_controller).to receive(:is_a?).with(Devise::SessionsController).and_return(true)
      allow(sessions_controller).to receive(:is_a?).with(Devise::RegistrationsController).and_return(false)
      
      allow(registrations_controller).to receive(:is_a?).with(Devise::SessionsController).and_return(false)
      allow(registrations_controller).to receive(:is_a?).with(Devise::RegistrationsController).and_return(true)
      
      allow(other_controller).to receive(:is_a?).with(Devise::SessionsController).and_return(false)
      allow(other_controller).to receive(:is_a?).with(Devise::RegistrationsController).and_return(false)
    end

    context 'when CAPTCHA is enabled' do
      before do
        allow(CaptchaHelper).to receive(:enabled?).and_return(true)
      end

      it 'returns true for sessions controller' do
        expect(CaptchaHelper.required_for?(sessions_controller)).to be true
      end

      it 'returns true for registrations controller' do
        expect(CaptchaHelper.required_for?(registrations_controller)).to be true
      end

      it 'returns false for other controllers' do
        expect(CaptchaHelper.required_for?(other_controller)).to be false
      end
    end

    context 'when CAPTCHA is disabled' do
      before do
        allow(CaptchaHelper).to receive(:enabled?).and_return(false)
      end

      it 'returns false' do
        expect(CaptchaHelper.required_for?(sessions_controller)).to be false
      end
    end
  end
end
