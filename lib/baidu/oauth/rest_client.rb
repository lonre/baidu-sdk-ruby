# encoding: UTF-8

module Baidu
  module OAuth
    # 通过百度开放平台提供的REST API，第三方应用可以获取到百度用户的用户资料、
    # 好友关系等基本信息，以及今后百度开放的其他任何数据，
    # 但前提是应用必须获得到百度开放平台和百度用户的授权。
    class RESTClient
      include Baidu::Support::Request

      # 创建一个 REST API Client 实例
      #
      # @example
      #   rest_client = Baidu::OAuth::RESTClient.new('my_token...')
      #
      # @overload initialize(access_token)
      #   @param [String] access_token
      #
      # @overload initialize(session)
      #   @param [Baidu::Session] session
      def initialize(access_token_or_session)
        @access_token = case access_token_or_session
                        when String then access_token_or_session
                        when Baidu::Session then access_token_or_session.access_token
                        else
                          raise ArgumentError, 'need a String or Baidu::Session'
                        end
        @site = Baidu::OAuth::SITE
      end

      # 获取当前登录用户的简单信息
      #
      # 获取当前登录用户的用户uid、用户名和头像。
      # @note 如果存储用户信息的话，请大家以百度用户uid为主键
      #
      # @example 返回的原始 JSON
      #   {
      #     "uid": "256758493",
      #     "uname": "XiaoLu",
      #     "portrait": "b4994c6849380284916e67af0c"
      #   }
      #
      #   :uid      当前登录用户的数字ID
      #   :uname    当前登录用户的用户名。只用于显示，可能会发生变化，不保证全局唯一
      #   :portrait 当前登录用户的头像
      #
      #   头像的地址具体如下：
      #   small image: http://tb.himg.baidu.com/sys/portraitn/item/{$portrait}
      #   large image: http://tb.himg.baidu.com/sys/portrait/item/{$portrait}
      #
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E8.8E.B7.E5.8F.96.E5.BD.93.E5.89.8D.E7.99.BB.E5.BD.95.E7.94.A8.E6.88.B7.E7.9A.84.E7.AE.80.E5.8D.95.E4.BF.A1.E6.81.AF 获取当前登录用户的信息
      def get_logged_in_user
        api_request '/passport/users/getLoggedInUser'
      end

      # 返回用户详细资料
      # @note 如果存储用户信息的话，请大家以百度用户uid为主键
      #
      # @example 返回的原始 JSON
      #   {
      #       "userid":"2097322476",
      #       "username":"wl19871011",
      #       "realname":"阳光",
      #       "userdetail":"喜欢自由",
      #       "birthday":"1987-01-01",
      #       "marriage":"恋爱",
      #       "sex":"男",
      #       "blood":"O",
      #       "constellation":"射手",
      #       "figure":"小巧",
      #       "education":"大学/专科",
      #       "trade":"计算机/电子产品",
      #       "job":"未知",
      #       "birthday_year":"1987",
      #       "birthday_month":"01",
      #       "birthday_day":"01"
      #   }
      #
      #   :userid        当前登录用户的数字ID
      #   :username      当前登录用户的用户名，值可能为空。
      #   :realname      用户真实姓名，可能为空。
      #   :portrait      当前登录用户的头像
      #   :userdetail    自我简介，可能为空。
      #   :birthday      生日，以yyyy-mm-dd格式显示。
      #   :marriage      婚姻状况
      #   :sex           性别
      #   :blood         血型
      #   :figure        体型
      #   :constellation 星座
      #   :education     学历
      #   :trade         当前职业
      #   :job           职位
      #
      #   头像的地址具体如下：
      #   small image: http://tb.himg.baidu.com/sys/portraitn/item/{$portrait}
      #   large image: http://tb.himg.baidu.com/sys/portrait/item/{$portrait}
      #
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E8.BF.94.E5.9B.9E.E7.94.A8.E6.88.B7.E8.AF.A6.E7.BB.86.E8.B5.84.E6.96.99 返回用户详细资料
      def get_info
        api_request '/passport/users/getInfo'
      end

      # 判定当前用户是否已经为应用授权
      #
      # @option options [String] :uid   用户uid,为空则默认是当前用户
      # @option options [String] :appid 应用的appid,为空则默认是当前应用
      #
      # @return [Boolean]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E5.88.A4.E5.AE.9A.E5.BD.93.E5.89.8D.E7.94.A8.E6.88.B7.E6.98.AF.E5.90.A6.E5.B7.B2.E7.BB.8F.E4.B8.BA.E5.BA.94.E7.94.A8.E6.8E.88.E6.9D.83 判定当前用户是否已经为应用授权
      def app_user?(options={})
        rest = api_request '/passport/users/isAppUser', options
        rest[:result] == '1'
      end

      # 判断指定用户是否具有某个数据操作权限
      #
      # 根据用户id以及在百度的相应的操作权限(单个权限，例如接收email等)来判断用户是否可以进行此操作。
      #
      # @param [String] ext_perm 单个权限，例如接收email等，具体权限请查看权限列表
      # @param [String] uid      用户uid，为空则默认是当前用户
      #
      # @return [Boolean]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E5.88.A4.E6.96.AD.E6.8C.87.E5.AE.9A.E7.94.A8.E6.88.B7.E6.98.AF.E5.90.A6.E5.85.B7.E6.9C.89.E6.9F.90.E4.B8.AA.E6.95.B0.E6.8D.AE.E6.93.8D.E4.BD.9C.E6.9D.83.E9.99.90 判断指定用户是否具有某个数据操作权限
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth#.E6.8E.88.E6.9D.83.E6.9D.83.E9.99.90.E5.88.97.E8.A1.A8 权限列表
      def has_app_permission?(ext_perm, uid=nil)
        body = { ext_perm: ext_perm, uid: uid }
        rest = api_request '/passport/users/hasAppPermission', body
        rest[:result] == '1'
      end

      # 判断指定用户是否具有某一批数据操作权限
      #
      # 根据用户id以及在百度的相应的操作权限(可以是多个权限半角逗号隔开)来判断用户是否可以进行此操作
      #
      # @example 返回的原始 JSON
      #   {"basic":"1","email":"0"}
      #
      # @overload has_app_permissions(ext_perm, uid=nil)
      #   @param [String] ext_perm 多个权限半角逗号隔开，例如basic,email等，具体权限请查看权限列表
      #   @param [String] uid      用户uid，为空则默认是当前用户
      #
      # @overload has_app_permissions(ext_perms, uid=nil)
      #   @param [Array<String>] ext_perms 权限字符串数组，具体权限请查看权限列表
      #   @param [String]        uid       用户uid，为空则默认是当前用户
      #
      # @return [Hash]
      #            各个值在原始 JSON 基础之上转换为 true 或者 false
      #              如：{:basic=>true, :email=>false}
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E5.88.A4.E6.96.AD.E6.8C.87.E5.AE.9A.E7.94.A8.E6.88.B7.E6.98.AF.E5.90.A6.E5.85.B7.E6.9C.89.E6.9F.90.E4.B8.80.E6.89.B9.E6.95.B0.E6.8D.AE.E6.93.8D.E4.BD.9C.E6.9D.83.E9.99.90 判断指定用户是否具有某一批数据操作权限
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth#.E6.8E.88.E6.9D.83.E6.9D.83.E9.99.90.E5.88.97.E8.A1.A8 权限列表
      def has_app_permissions(ext_perms, uid=nil)
        body = { ext_perms: ext_perms, uid: uid }
        if ext_perms.is_a? Array
          body[:ext_perms] = ext_perms.join ','
        end

        rest = api_request '/passport/users/hasAppPermissions', body
        rest.each { |k, v| rest[k] = v == '1' }
      end

      # 返回用户好友资料
      #
      # 根据用户id以及在百度的相应的操作权限(可以是多个权限半角逗号隔开)来判断用户是否可以进行此操作
      # @todo TODO: check return value
      #
      # @example 返回的原始 JSON
      #   [
      #     {
      #       "uname": "spacebj009",
      #       "uid": "2013411308",
      #       "portrait": "79787370616365626a3030393306"
      #     },
      #     {
      #       "uname": "spacebj003",
      #       "uid": "2013412844",
      #       "portrait": "73787370616365626a3030333306"
      #     }
      #   ]
      #
      #   :uname    好友的用户名
      #   :uid      当前登录用户的数字ID
      #   :portrait 好友的用户头像加密串
      #
      # @option options [Fixnum] :page_no   用于支持分页的API，0表示第1页，默认为0
      # @option options [Fixnum] :page_size 用于支持分页的API，表示每页返回多少条数据，默认值500
      # @option options [String] :sort_type 0: 按照添加时间排序，1：登陆时间排序，默认为0
      #
      # @return [Array]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E8.BF.94.E5.9B.9E.E7.94.A8.E6.88.B7.E5.A5.BD.E5.8F.8B.E8.B5.84.E6.96.99 返回用户好友资料
      def get_friends(options={})
        api_request '/friends/getFriends', options
      end

      # 获得指定用户之间好友关系
      #
      # 获得指定用户之间是否是好友关系。第一个数组指定一半用户，第二个数组指定另外一半，
      # 两个数组必须同样的个数，一次最多可以查20个
      #
      # @example 返回的原始 JSON
      #   [
      #     {
      #       "uid1": "2222",
      #       "uid2": "1111",
      #       "are_friends": "1",
      #       "are_friends_reverse": "0"
      #     },
      #     {
      #       "uid1": "3333",
      #       "uid2": "2222",
      #       "are_friends": "0",
      #       "are_friends_reverse": "1"
      #     }
      #   ]
      #
      #   :are_friends         uid2是否是uid1的好友
      #   :are_friends_reverse uid1是否是uid2的好友
      #
      # @overload are_friends(uid1, uid2)
      #   @param [String] uid1
      #   @param [String] uid2
      #
      # @overload are_friends(uids1, uids2)
      #   @param [Array<String>] uids1
      #   @param [Array<String>] uids2
      #
      # @return [Array]
      #            are_friends 和 are_friends_reverse 值在原始 JSON 基础之上转换为 true 或者 false
      #              如：[{:uid1=>"22", :uid2=>"33", :are_friends=>false, :are_friends_reverse=>true}]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E8.8E.B7.E5.BE.97.E6.8C.87.E5.AE.9A.E7.94.A8.E6.88.B7.E4.B9.8B.E9.97.B4.E5.A5.BD.E5.8F.8B.E5.85.B3.E7.B3.BB 获得指定用户之间好友关系
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

      # 使access_token,session_key过期
      #
      # 使用户授予的access_token和session_key过期
      #
      # @return [Boolean] true: 成功 false: 失败
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E4.BD.BFaccess_token.2Csession_key.E8.BF.87.E6.9C.9F 使access_token,session_key过期
      def expire_session
        rest = api_request '/passport/auth/expireSession'
        rest[:result] == '1'
      end

      # 撤销用户授予第三方应用的权限
      #
      # @param [String] uid 用户的ID,空则默认为当前用户
      #
      # @return [Boolean] true: 成功 false: 失败
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E6.92.A4.E9.94.80.E7.94.A8.E6.88.B7.E6.8E.88.E4.BA.88.E7.AC.AC.E4.B8.89.E6.96.B9.E5.BA.94.E7.94.A8.E7.9A.84.E6.9D.83.E9.99.90 撤销用户授予第三方应用的权限
      def revoke_authorization(uid=nil)
        rest = api_request('/passport/auth/revokeAuthorization', {uid: uid})
        rest[:result] == '1'
      end

      # 查询IP地址所在地区
      #
      # @example
      #   rest_client.query_ip '111.222.111.222', '114.114.114.114'
      #
      # @example 返回的原始 JSON
      #   {
      #     "111.222.111.222": {
      #       "province": "\u5e7f\u4e1c",
      #       "city": "\u6df1\u5733"
      #     },
      #     "111.222.111.222": {
      #       "province": ""\u6c5f\u82cf",
      #       "city": ""
      #     }
      #   }
      #
      # @param [*String] ips 需要查询的ip地址
      #
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/rest/file_data_apis_list#.E6.9F.A5.E8.AF.A2IP.E5.9C.B0.E5.9D.80.E6.89.80.E5.9C.A8.E5.9C.B0.E5.8C.BA 查询IP地址所在地区
      def query_ip(*ips)
        api_request('/iplib/query', { ip: ips.join(',') }, :get)
      end

      private

      def base_query
        { access_token: @access_token }
      end

      def api_request(path, params={}, method=:post)
        body = base_query.update params
        rest =
          case method
          when :post
            post "#{BASE_PATH}#{path}", nil, body
          when :get
            get "#{BASE_PATH}#{path}", body
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
