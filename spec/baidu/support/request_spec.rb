# encoding: UTF-8

require 'spec_helper'
require 'baidu/pcs'

describe Baidu::Support::Request do
  before :all do
    Baidu.config do |c|
      c.pcs_dir_name = 'Backups'
    end
    @client = Baidu::PCS::Client.new('ATOKEN')
  end

  describe '#request' do
    it 'needs rewrite with no pcs be required'

    describe 'got redirection status code' do
      it 'redirects 302 response' do
        stub_request(:get, 'baidu.com/notfound').to_return(status: 302, headers: { Location: 'http://baidu.com' })
        stub_request(:get, 'baidu.com/').to_return(status: 200, body: 'stop redirect')

        @client.get('/notfound', nil, site: 'http://baidu.com', raw: true)
        a_request(:get, 'baidu.com/notfound').should have_been_made
        a_request(:get, 'baidu.com').should have_been_made
      end

      it 'throw exception with infinite redirect loop' do
        stub_request(:get, 'baidu.com/loop').to_return(status: 302, headers: { Location: 'http://baidu.com/loop' })
        expect {
          @client.get('/loop', nil, site: 'http://baidu.com')
        }.to raise_error(Baidu::Errors::Error)
      end
    end

    describe 'got other status code' do
      it 'requests with invalid access token' do
        stub_request(:get, 'baidu.com/noaccess').to_return(status: 401)
        expect {
          @client.get('/noaccess', nil, site: 'http://baidu.com')
        }.to raise_error(Baidu::Errors::AuthError)
      end

      it 'requests with invalid api' do
        stub_request(:get, 'baidu.com/invalid').to_return(status: 400)
        expect {
          @client.get('/invalid', nil, site: 'http://baidu.com')
        }.to raise_error(Baidu::Errors::ClientError)
      end

      it 'requests with server error' do
        stub_request(:get, 'baidu.com/serverfault').to_return(status: 500)
        expect {
          @client.get('/serverfault', nil, site: 'http://baidu.com')
        }.to raise_error(Baidu::Errors::ServerError)
      end
    end
  end
end
