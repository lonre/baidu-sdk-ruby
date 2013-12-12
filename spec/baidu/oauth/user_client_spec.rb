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

    describe '#get_info' do
      it 'requests current user info' do
        stub = stub_post(:oauth_rest, '/passport/users/getInfo', base_query)
        @client.get_info
        stub.should have_been_requested
      end

      it 'requests specified user info' do
        stub = stub_post(:oauth_rest, '/passport/users/getInfo', base_query.update({ uid: '123456' }))
        @client.get_info(uid: '123456')
        stub.should have_been_requested
      end

      it 'requests with fields' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/getInfo',
                         base_query.update({ uid: '654321', fields: 'realname,portrait' }))
        @client.get_info(uid: '654321', fields: 'realname,portrait')
        stub.should have_been_requested
      end
    end
  end
end