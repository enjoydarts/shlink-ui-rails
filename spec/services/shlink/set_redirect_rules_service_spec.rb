require 'rails_helper'

RSpec.describe Shlink::SetRedirectRulesService, type: :service do
  let(:service) { described_class.new }
  let(:short_code) { 'abc123' }
  let(:redirect_rules) do
    [
      {
        longUrl: 'https://play.google.com/store/apps/details?id=example',
        conditions: [
          { type: "device", matchValue: "android", matchKey: nil }
        ]
      },
      {
        longUrl: 'https://apps.apple.com/app/id123456789',
        conditions: [
          { type: "device", matchValue: "ios", matchKey: nil }
        ]
      }
    ]
  end

  describe '#call' do
    before do
      stub_request(:post, "#{Settings.shlink.base_url}/rest/v3/short-urls/#{short_code}/redirect-rules")
        .with(
          headers: {
            'X-Api-Key' => Settings.shlink.api_key,
            'Content-Type' => 'application/json'
          },
          body: { redirectRules: redirect_rules }.to_json
        )
        .to_return(
          status: 200,
          body: { redirectRules: redirect_rules }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'Shlink APIにリダイレクトルールを設定する' do
      result = service.call(short_code: short_code, redirect_rules: redirect_rules)

      expect(result).to have_key('redirectRules')
      expect(result['redirectRules']).to be_an(Array)
      expect(result['redirectRules'].length).to eq(2)
    end

    context 'APIエラーが発生した場合' do
      before do
        stub_request(:post, "#{Settings.shlink.base_url}/rest/v3/short-urls/#{short_code}/redirect-rules")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'Shlink::Errorを発生させる' do
        expect {
          service.call(short_code: short_code, redirect_rules: redirect_rules)
        }.to raise_error(Shlink::Error)
      end
    end

    context 'ネットワークエラーが発生した場合' do
      before do
        stub_request(:post, "#{Settings.shlink.base_url}/rest/v3/short-urls/#{short_code}/redirect-rules")
          .to_raise(Faraday::ConnectionFailed)
      end

      it 'Shlink::Errorを発生させる' do
        expect {
          service.call(short_code: short_code, redirect_rules: redirect_rules)
        }.to raise_error(Shlink::Error, /HTTP error:/)
      end
    end
  end
end
