# encoding: UTF-8

require 'spec_helper'
require 'baidu/oauth'

module Baidu
  describe OAuth::UserClient do
    let(:base_query) { { access_token: '3.xxx.yyy' } }

    before do
      @client = OAuth::UserClient.new(base_query[:access_token])
    end

    describe '#initialize' do
      it 'inits with access token string' do
        client = OAuth::UserClient.new('xyz_at')
        expect(client).to be_a(OAuth::UserClient)
        expect(client.instance_variable_get(:@access_token)).to eq('xyz_at')
      end

      it 'inits with Baidu::Session' do
        session = Baidu::Session.new
        session.access_token = 'zyx_at'
        client = OAuth::UserClient.new(session)
        expect(client).to be_a(OAuth::UserClient)
        expect(client.instance_variable_get(:@access_token)).to eq('zyx_at')
      end

      it 'provides base uri' do
        client = OAuth::UserClient.new('xyz_at')
        expect(client.instance_variable_get(:@site)).to eq('https://openapi.baidu.com')
      end

      it 'raises error with other params' do
        expect {
          OAuth::UserClient.new({})
        }.to raise_error(ArgumentError, 'need a String or Baidu::Session')
      end
    end

    describe '#get_logged_in_user' do
      it 'requests with params' do
        stub = stub_post(:oauth_rest, '/passport/users/getLoggedInUser', base_query)
        @client.get_logged_in_user
        stub.should have_been_requested
      end
    end
  end
end