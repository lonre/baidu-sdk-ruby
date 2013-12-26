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
        api_request '/passport/users/getLoggedInUser'
      end

      def get_info(options={})
        api_request '/passport/users/getInfo', options
      end

      def app_user?(options={})
        rest = api_request '/passport/users/isAppUser', options
        rest[:result] == '1'
      end

      def has_app_permission?(ext_perm, uid=nil)
        body = { ext_perm: ext_perm, uid: uid }
        rest = api_request '/passport/users/hasAppPermission', body
        rest[:result] == '1'
      end

      def has_app_permissions(ext_perms, uid=nil)
        body = { ext_perms: ext_perms, uid: uid }
        if ext_perms.is_a? Array
          body[:ext_perms] = ext_perms.join ','
        end

        rest = api_request '/passport/users/hasAppPermissions', body
        rest.each { |k, v| rest[k] = v == '1' }
      end

      # TODO: check return value
      def get_friends(options={})
        api_request '/friends/getFriends', options
      end

      def are_friends(uids1, uids2)
        body = {}
        case
        when uids1.is_a?(String) && uids2.is_a?(String)
          body[:uids1], body[:uids2] = uids1, uids2
        when uids1.is_a?(Array)  && uids2.is_a?(Array)
          raise ArgumentError, 'not the same size of array' unless uids1.size == uids2.size
          body[:uids1], body[:uids2] = uids1.join(','), uids2.join(',')
        else
          raise ArgumentError, 'not the same types'
        end

        rest = api_request '/friends/areFriends', body
        rest.each do |h|
          h[:are_friends] = h[:are_friends] == '1'
          h[:are_friends_reverse] = h[:are_friends_reverse] == '1'
        end
      end

      def expire_session
        rest = api_request '/passport/auth/expireSession'
        rest[:result] == '1'
      end

      def revoke_authorization(uid=nil)
        rest = api_request('/passport/auth/revokeAuthorization', {uid: uid})
        rest[:result] == '1'
      end

      private

      def base_query
        { access_token: @access_token }
      end

      def api_request(path, body={}, method=:post)
        body = base_query.update body
        rest =
          case method
          when :post
            post "#{BASE_PATH}#{path}", nil, body
          end
        process_error rest
        rest
      end

      # NOTE: Baidu api sucks, it may return error info with 200 status
      # http://developer.baidu.com/wiki/index.php?title=%E7%99%BE%E5%BA%A6Open_API%E9%94%99%E8%AF%AF%E7%A0%81%E5%AE%9A%E4%B9%89
      def process_error(data)
        if data.is_a?(Hash) && data.has_key?(:error_code)
          code = data[:error_code].to_s.strip
          msg  = data[:error_msg]
          unless code == '0'
            if %w[102 110 111 112].include? code
              raise Baidu::Errors::AuthError.new(msg, code)
            else
              raise Baidu::Errors::Error.new(msg, code)
            end
          end
        end
      end
    end
  end
end
