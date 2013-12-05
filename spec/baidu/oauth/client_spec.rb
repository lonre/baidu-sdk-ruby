# encoding: UTF-8

require 'spec_helper'
require 'baidu/oauth'

describe Baidu::OAuth::Client do
  let(:authorization_endpoint) { 'https://openapi.baidu.com/oauth/2.0/authorize' }
  let(:device_endpoint) { 'https://openapi.baidu.com/oauth/2.0/device/code' }

  before(:all) do
    Baidu.config do |c|
      c.client_id     = 'ci'
      c.client_secret = 'cs'
    end
  end

  before(:each) do
    @client = Baidu::OAuth::Client.new do |config|
      config.access_token   = 'at'
      config.refresh_token  = 'rt'
      config.session_key    = 'sk'
      config.session_secret = 'ss'
    end
  end

  context '.initialize' do
    it 'assigns right config' do
      expect(@client.client_id).to     eq('ci')
      expect(@client.client_secret).to eq('cs')
    end

    it 'overwrites client_id and client_secret' do
      @client = Baidu::OAuth::Client.new('ci2', 'cs2')
      expect(@client.client_id).to     eq('ci2')
      expect(@client.client_secret).to eq('cs2')
    end

    it 'does not touch endpoint' do
      expect(Baidu::OAuth::SITE).to eq('https://openapi.baidu.com')
      expect(Baidu::OAuth::AUTHORIZATION_ENDPOINT).to eq('/oauth/2.0/authorize')
      expect(Baidu::OAuth::TOKEN_ENDPOINT).to eq('/oauth/2.0/token')
      expect(@client.instance_variable_get('@site')).to eq('https://openapi.baidu.com')
    end
  end

  context '#authorize_url' do
    context 'with code flow' do
      it 'generates "Authorization Code" authorize url' do
        url = @client.code_flow.authorize_url('oob')
        expect(url).to eq("#{authorization_endpoint}?response_type=code&display=page&" \
                          "client_id=ci&redirect_uri=oob")
      end

      it 'generates "Authorization Code" authorize url with params' do
        url = @client.code_flow.authorize_url('http://www.example.com/oauth_redirect',
                                                scope: 'email', state: 'xyz', display: 'tv',
                                                force_login: true, confirm_login: true)
        expect(url).to eq("#{authorization_endpoint}?response_type=code&display=tv&" \
                          "scope=email&state=xyz&force_login=1&confirm_login=1&client_id=ci&" \
                          "redirect_uri=http%3A%2F%2Fwww.example.com%2Foauth_redirect")
      end
    end

    context 'with implicit flow' do
      it 'generates "Implicit Grant" authorize url' do
        url = @client.implicit_flow.authorize_url('oob')
        expect(url).to eq("#{authorization_endpoint}?response_type=token&display=page&" \
                          "client_id=ci&redirect_uri=oob")
      end

      it 'generates "Implicit Grant" authorize url with params' do
        url = @client.implicit_flow.authorize_url('http://www.example.com/oauth_redirect',
                                                scope: 'basic email', state: 'xyz', display: 'mobile',
                                                force_login: true, confirm_login: true)
        expect(url).to eq("#{authorization_endpoint}?response_type=token&display=mobile&" \
                          "scope=basic+email&state=xyz&force_login=1&confirm_login=1&client_id=ci&" \
                          "redirect_uri=http%3A%2F%2Fwww.example.com%2Foauth_redirect")
      end
    end
  end

  context '#user_and_device_code' do

    it 'requests user and device code' do
      stub_get(:oauth, '/oauth/2.0/device/code', client_id: 'ci', response_type: 'device_code').
        to_return(status: 200, body: ft('user_and_device_code.json'))
      @client.device_flow.user_and_device_code
      a_get(:oauth, '/oauth/2.0/device/code', client_id: 'ci', response_type: 'device_code').
        should have_been_made
    end

    it 'requests user and device code with scope' do
      stub_get(:oauth, '/oauth/2.0/device/code', client_id: 'ci',
               response_type: 'device_code', scope: 'basic netdisk').
        to_return(status: 200, body: ft('user_and_device_code.json'))
      @client.device_flow.user_and_device_code 'basic netdisk'
      a_get(:oauth, '/oauth/2.0/device/code', client_id: 'ci',
            response_type: 'device_code', scope: 'basic netdisk').
        should have_been_made
    end

    it 'responses user and device code' do
      stub_get(:oauth, '/oauth/2.0/device/code', client_id: 'ci', response_type: 'device_code').
        to_return(status: 200, body: ft('user_and_device_code.json'))
      result = @client.device_flow.user_and_device_code
      expect(result).to be_instance_of(Hash)
      expect(result).to have_key(:device_code)
      expect(result).to have_key(:user_code)
      expect(result).to have_key(:verification_url)
      expect(result).to have_key(:qrcode_url)
      expect(result).to have_key(:expires_in)
      expect(result).to have_key(:interval)
    end
  end

  context '#get_token' do
    context 'with code flow' do
      before do
        stub_post(:oauth, '/oauth/2.0/token',
                  grant_type: 'authorization_code',
                  code: 'ANXxSNjwQDugOnqeikRMu2bKaXCdlLxn',
                  client_id: 'ci', client_secret: 'cs',
                  redirect_uri: 'http://www.example.com/oauth_redirect').
          to_return(status: 200, body: ft('get_token_code.json'))
      end

      it 'requests access tokey' do
        @client.code_flow.get_token 'ANXxSNjwQDugOnqeikRMu2bKaXCdlLxn',
                                     'http://www.example.com/oauth_redirect'
        a_post(:oauth, '/oauth/2.0/token',
                grant_type: 'authorization_code',
                code: 'ANXxSNjwQDugOnqeikRMu2bKaXCdlLxn',
                client_id: 'ci', client_secret: 'cs',
                redirect_uri: 'http://www.example.com/oauth_redirect').should have_been_made
      end

      it 'responses access token' do
        result = @client.code_flow.get_token 'ANXxSNjwQDugOnqeikRMu2bKaXCdlLxn',
                                              'http://www.example.com/oauth_redirect'
        expect(result).to be_instance_of(Baidu::Session)
        expect(result).to respond_to(:access_token)
        expect(result).to respond_to(:refresh_token)
        expect(result).to respond_to(:scope)
        expect(result).to respond_to(:session_key)
        expect(result).to respond_to(:session_secret)
      end
    end

    context 'with device flow' do
      before do
        stub_post(:oauth, '/oauth/2.0/token', grant_type: 'device_token',
                  code: 'a82hjs723h72h3a82hjs723h72h3vb', client_id: 'ci', client_secret: 'cs').
          to_return(status: 200, body: ft('get_token_device.json'))
      end

      it 'requests access token' do
        @client.device_flow.get_token 'a82hjs723h72h3a82hjs723h72h3vb'
        a_post(:oauth, '/oauth/2.0/token', grant_type: 'device_token',
               code: 'a82hjs723h72h3a82hjs723h72h3vb',
               client_id: 'ci', client_secret: 'cs').should have_been_made
      end

      it 'responses access token' do
        result = @client.device_flow.get_token 'a82hjs723h72h3a82hjs723h72h3vb'
        expect(result).to be_instance_of(Baidu::Session)
        expect(result).to respond_to(:access_token)
        expect(result).to respond_to(:refresh_token)
        expect(result).to respond_to(:scope)
        expect(result).to respond_to(:session_key)
        expect(result).to respond_to(:session_secret)
      end
    end
  end

  context 'with client credentials' do
    let(:base_params) do
      { grant_type: 'client_credentials', client_id: 'ci', client_secret: 'cs' }
    end

    it 'requests access token' do
      stub = stub_post(:oauth, '/oauth/2.0/token', base_params)
      @client.client_credentials_flow.get_token
      stub.should have_been_requested
    end

    it 'requests access token with scope' do
      stub = stub_post(:oauth, '/oauth/2.0/token', base_params.update({ scope: 'basic hao123' }))
      @client.client_credentials_flow.get_token('basic hao123')
      stub.should have_been_requested
    end

    it 'responses access token' do
      stub = stub_post(:oauth, '/oauth/2.0/token', base_params).
        to_return(status: 200, body: ft('get_token_client_credentials.json'))
      result = @client.client_credentials_flow.get_token
      expect(result).to be_instance_of(Baidu::Session)
      expect(result).to respond_to(:access_token)
      expect(result).to respond_to(:refresh_token)
      expect(result).to respond_to(:scope)
      expect(result).to respond_to(:session_key)
      expect(result).to respond_to(:session_secret)
    end
  end

  context '#refresh_token' do
    before do
      stub_post(:oauth, '/oauth/2.0/token', grant_type: 'refresh_token',
                refresh_token: '2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328',
                client_id: 'ci', client_secret: 'cs').
        to_return(status: 200, body: ft('refresh_token.json'))
    end

    it 'requests access token by refresh token' do
      @client.refresh('2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328')
      a_post(:oauth, '/oauth/2.0/token', grant_type: 'refresh_token',
             refresh_token: '2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328',
             client_id: 'ci', client_secret: 'cs').should have_been_made
    end

    it 'requests access token by  refresh token with params' do
      stub_post(:oauth, '/oauth/2.0/token', grant_type: 'refresh_token',
                refresh_token: '2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328',
                scope: 'basic netdisk', client_id: 'ci', client_secret: 'cs').
        to_return(status: 200, body: ft('refresh_token.json'))
      @client.refresh('2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328',
                      scope: 'basic netdisk')
      a_post(:oauth, '/oauth/2.0/token', grant_type: 'refresh_token',
             refresh_token: '2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328',
             scope: 'basic netdisk', client_id: 'ci', client_secret: 'cs').should have_been_made
    end

    it 'responses access token by refresh token' do
      result = @client.refresh('2.af3d55f8615fdfd9edb7c4b5ebdc3e32.604800.1293440400-2346678-124328')
      expect(result).to be_instance_of(Baidu::Session)
      expect(result).to respond_to(:access_token)
      expect(result).to respond_to(:refresh_token)
      expect(result).to respond_to(:scope)
      expect(result).to respond_to(:session_key)
      expect(result).to respond_to(:session_secret)
    end
  end
end
