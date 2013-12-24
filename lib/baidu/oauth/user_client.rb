# encoding: UTF-8

module Baidu
  module OAuth
    class UserClient
      include Baidu::Support::Request

      def initialize(access_token_or_session)
        @access_token = case access_token_or_session
                        when String then access_token_or_session
                        when Baidu::Session then access_token_or_session.access_token
                        else
                          raise ArgumentError, 'need a String or Baidu::Session'
                        end
        @site = Baidu::OAuth::SITE
      end

      def get_logged_in_user
        post "#{BASE_PATH}/passport/users/getLoggedInUser", nil, base_query
      end

      def get_info(options={})
        body          = base_query
        body[:uid]    = options[:uid]
        body[:fields] = options[:fields]

        post "#{BASE_PATH}/passport/users/getInfo", nil, body
      end

      def app_user?(options={})
        body         = base_query
        body[:uid]   = options[:uid]
        body[:appid] = options[:appid]

        rest = post "#{BASE_PATH}/passport/users/isAppUser", nil, body
        rest[:result] == '1'
      end

      def has_app_permission?(ext_perm, uid=nil)
        body            = base_query
        body[:ext_perm] = ext_perm
        body[:uid]      = uid

        rest = post "#{BASE_PATH}/passport/users/hasAppPermission", nil, body
        rest[:result] == '1'
      end

      def has_app_permissions(ext_perms, uid=nil)
        body             = base_query
        body[:ext_perms] = ext_perms
        if ext_perms.is_a? Array
          body[:ext_perms] = ext_perms.join ','
        end
        body[:uid]       = uid

        rest = post "#{BASE_PATH}/passport/users/hasAppPermissions", nil, body
        rest.each { |k, v| rest[k] = v == '1' }
      end

      # TODO: check return value
      def get_friends(options={})
        post "#{BASE_PATH}/friends/getFriends", nil, base_query.update(options)
      end

      private

      def base_query
        { access_token: @access_token }
      end
    end
  end
end
