RSpec.describe OmniAuth::Strategies::TLS do
  let(:dn_cn) { 'Jane Johnsonn' }
  let(:dn_email) { 'jan@john.sonn' }
  let(:dn) { "/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=#{dn_cn}/emailAddress=#{dn_email}" }

  let(:v_end) { 'Apr 13 12:31:53 2019 GMT' }
  let(:client_verify) { 'SUCCESS'.freeze }

  let(:request_env) { { 'SSL_CLIENT_S_DN' => dn, 'SSL_CLIENT_V_END' => v_end, 'SSL_CLIENT_VERIFY' => client_verify } }
  let(:request) { double(Rack::Request, env: request_env) }

  let(:app) do
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use OmniAuth::Strategies::TLS
      run lambda { |env| [404, { 'Content-Type' => 'text/plain' }, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end
  let(:tls_strategy) { OmniAuth::Strategies::TLS.new app }

  before do
    allow(tls_strategy).to receive(:request).and_return request
  end

  describe '#auth_hash' do
    subject { tls_strategy.auth_hash }

    it 'has all important fields' do
      expect(subject).to include(provider: 'tls', uid: dn)
      expect(subject.info).to include(name: dn_cn, email: dn_email)
    end
  end
end
