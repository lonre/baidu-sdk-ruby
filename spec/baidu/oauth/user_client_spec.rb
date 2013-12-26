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

    describe '#app_user?' do
      it 'requests "isAppUser" api' do
        stub = stub_post(:oauth_rest, '/passport/users/isAppUser', base_query)
        @client.app_user?
        stub.should have_been_requested
      end

      it 'requests "isAppUser" for specified user' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/isAppUser',
                         base_query.update({ uid: '456123' }))
        stub.to_return(body: '{"result":"1"}')
        rest = @client.app_user?(uid: '456123')
        stub.should have_been_requested
        expect(rest).to be_true
      end

      it 'requests "isAppUser" for specified appid' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/isAppUser',
                         base_query.update({ appid: '341256' }))
        stub.to_return(body: '{"result":"0"}')
        rest = @client.app_user?(appid: '341256')
        stub.should have_been_requested
        expect(rest).to be_false
      end
    end

    describe '#has_app_permission?' do
      it 'requests "hasAppPermission" api' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/hasAppPermission',
                         base_query.update({ ext_perm: 'netdisk' }))
        stub.to_return(body: '{"result":"1"}')
        rest = @client.has_app_permission? 'netdisk'
        stub.should have_been_requested
        expect(rest).to be_true
      end

      it 'requests "hasAppPermission" for specified user' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/hasAppPermission',
                         base_query.update({ ext_perm: 'super_msg', uid: '456123' }))
        stub.to_return(body: '{"result":"0"}')
        rest = @client.has_app_permission?('super_msg', '456123')
        stub.should have_been_requested
        expect(rest).to be_false
      end
    end

    describe '#has_app_permissions' do
      it 'requests "hasAppPermissions" api' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/hasAppPermissions',
                         base_query.update({ ext_perms: 'netdisk,basic' }))
        stub.to_return(body: '{"basic":"1", "netdisk":"0"}')
        rest = @client.has_app_permissions 'netdisk,basic'
        stub.should have_been_requested
        expect(rest[:basic]).to   be_true
        expect(rest[:netdisk]).to be_false
      end

      it 'requests "hasAppPermissions" api with array of perms' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/hasAppPermissions',
                         base_query.update({ ext_perms: 'netdisk,basic' }))
        stub.to_return(body: '{"basic":"1", "netdisk":"0"}')
        rest = @client.has_app_permissions %w[netdisk basic]
        stub.should have_been_requested
        expect(rest[:basic]).to   be_true
        expect(rest[:netdisk]).to be_false
      end

      it 'requests "hasAppPermissions" for specified user' do
        stub = stub_post(:oauth_rest,
                         '/passport/users/hasAppPermissions',
                         base_query.update({ ext_perms: 'super_msg', uid: '456123' }))
        stub.to_return(body: '{"super_msg":"0"}')
        rest = @client.has_app_permissions('super_msg', '456123')
        stub.should have_been_requested
        expect(rest[:super_msg]).to be_false
      end
    end

    describe '#get_friends' do
      it 'requests with default params' do
        stub = stub_post(:oauth_rest, '/friends/getFriends', base_query)
        @client.get_friends
        stub.should have_been_requested
      end

      it 'requests with custom params' do
        stub = stub_post(:oauth_rest,
                         '/friends/getFriends',
                         base_query.update({ page_no: 3, page_size: 10, sort_type: 1 }))
        @client.get_friends page_no: 3, page_size: 10, sort_type: 1
        stub.should have_been_requested
      end

      it 'returns result of an array' do
        stub = stub_post(:oauth_rest, '/friends/getFriends', base_query.update(page_size: 2))
        stub.to_return(body: ft('get_friends.json'))
        rest = @client.get_friends page_size: 2
        stub.should have_been_requested
        expect(rest).to be_a Array
        expect(rest.size).to be(2)
      end
    end

    describe '#are_friends' do
      it 'requests with both string params' do
        stub = stub_post(:oauth_rest,
                         '/friends/areFriends',
                         base_query.update(uids1: '111', uids2: '222'))
        @client.are_friends '111', '222'
        stub.should have_been_requested
      end

      it 'requests with both array params' do
        stub = stub_post(:oauth_rest,
                         '/friends/areFriends',
                         base_query.update(uids1: '111,333', uids2: '222,444'))
        @client.are_friends %w[111 333], %w[222 444]
        stub.should have_been_requested
      end

      it 'requests with different param type' do
        expect {
          @client.are_friends '111', %w[222]
        }.to raise_error ArgumentError, 'not the same types'
      end

      it 'requests with different size of array params' do
        expect {
          @client.are_friends %w[111], %w[222, 333]
        }.to raise_error ArgumentError, 'not the same size of array'
      end

      it 'changes result with true or false' do
        stub = stub_post(:oauth_rest,
                         '/friends/areFriends',
                         base_query.update(uids1: '111,333', uids2: '222,444'))
        stub.to_return(body: ft('are_friends.json'))
        rest = @client.are_friends %w[111 333], %w[222 444]
        stub.should have_been_requested
        expect(rest.first[:are_friends]).to be_true
        expect(rest.first[:are_friends_reverse]).to be_false
        expect(rest.last[:are_friends]).to be_false
        expect(rest.last[:are_friends_reverse]).to be_true
      end
    end

    describe '#expire_session' do
      it 'requests "expireSession" api successfully' do
        stub = stub_post(:oauth_rest,
                         '/passport/auth/expireSession',
                         base_query)
        stub.to_return(body: '{"result":"1"}')
        rest = @client.expire_session
        stub.should have_been_requested
        expect(rest).to be_true
      end

      it 'requests "expireSession" api unsuccessfully' do
        stub = stub_post(:oauth_rest,
                         '/passport/auth/expireSession',
                         base_query)
        stub.to_return(body: '{"result":"0"}')
        rest = @client.expire_session
        stub.should have_been_requested
        expect(rest).to be_false
      end
    end
  end
end
