# encoding: UTF-8

require 'baidu/oauth/flow/authorization_code'
require 'baidu/oauth/flow/device'
require 'baidu/oauth/flow/implicit_grant'
require 'baidu/oauth/flow/client_credentials'

module Baidu
  module OAuth
    class Client
      include Baidu::Support::Request

      # 申请创建应用后获取的 API Key
      # @return [String]
      attr_accessor :client_id
      # 申请创建应用后获取的 Secret Key
      # @return [String]
      attr_accessor :client_secret
      # @private
      attr_reader :site

      # 创建一个 OAuth API 实例
      #
      # @example 如果不使用全局配置，则可以在创建新实例时指定 +client_id+ 和 +client_secret+
      #   client = Baidu::OAuth::Client.new('a_client_id', 'a_client_secret')
      def initialize(client_id=Baidu.client_id, client_secret=Baidu.client_secret)
        @client_id     = client_id
        @client_secret = client_secret
        @site          = Baidu::OAuth::SITE
      end

      # @!method authorization_code_flow
      #   采用 Authorization Code 获取 Access Token 的授权验证流程
      #   @return [Flow::AuthorizationCode]
      #
      # @!method device_flow
      #   采用 Device Code 获取 Access Token 的授权验证流程
      #   @return [Flow::Device]
      #
      # @!method implicit_grant_flow
      #   采用 Implicit Grant 方式获取 Access Token 的授权验证流程
      #   @return [Flow::ImplicitGrant]
      #
      # @!method client_credentials_flow
      #   使用 Client Credentials 获取 Access Token 的授权验证流程
      #   @return [Flow::ClientCredentials]
      #
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/authorization Authorization Code 授权
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/device Device 授权
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/implicit Implicit Grant 授权
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/client Client Credentials 授权
      [:authorization_code, :device, :implicit_grant, :client_credentials].each do |flow|
        define_method("#{flow}_flow".to_sym) do
          klass_name = flow.to_s.split('_').map { |s| s.capitalize }.join
          Baidu::OAuth::Flow.const_get(klass_name).new self
        end
      end

      # 刷新 Access Token
      #
      # @param [String] token 用于刷新 Access Token 用的 Refresh Token
      # @option params [String] :scope 以空格分隔的权限列表，若不传递此参数，代表请求的数据访问操作权限与上次获取 Access Token 时一致。
      #                                通过 Refresh Token 刷新 Access Token 时所要求的scope权限范围必须小于等于上次获取 Access Token 时授予的权限范围。
      #                                关于权限的具体信息请参考“{http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表}”
      # @return [Baidu::Session]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/overview Access Token 生命周期
      def refresh(token, params={})
        body = {
          grant_type:    'refresh_token',
          refresh_token: token,
          client_id:     self.client_id,
          client_secret: self.client_secret
        }.update params
        rest = post Baidu::OAuth::TOKEN_ENDPOINT, nil, body
        return nil if rest.nil?
        Baidu::Session.from rest
      end

      # 查询Access Token对应的授权信息
      #
      # 该接口用于查询Access Token对应的授权相关信息，
      # 包括授权对象(应用)、授权用户、授权的权限、授权时间，过期时间。
      # @example 返回的原始 JSON
      #   {
      #       "client_id": "ZLycGmiUcCkrSb3t7zSD8uV6",
      #       "userid": 689911016,
      #       "scope": "basic super_msg",
      #       "create_time": 1364555477,
      #       "expire_in": 2591980
      #   }
      #
      #   :client_id   Access Token对应应用的Api Key
      #   :userid      授权用户的唯一id。如果Access Token是通过Client Credentials授权方式 获取的，则该字段值为0
      #   :scope       Access Token最终的访问范围，即用户实际授予的权限列表（用户在授权页面时，有可能会取消掉某些请求的权限）
      #   :create_time Access Token的生成时间(Unix时间戳)，以秒为单位
      #   :expires_in  Access Token剩余的有效时间，以秒为单位
      #
      # @param [String] access_token 授权之后应用得到的Access Token
      # @return [Hash] 如上描述
      # @return [nil]  若参数中传递的 Access Token 已经过期或者无效，则返回 nil
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/tokeninfo 校验Access Token
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表
      def token_info(access_token)
        body = { access_token: access_token }
        begin
          post Baidu::OAuth::TOKEN_INFO_ENDPOINT, nil, body
        rescue Baidu::Errors::ClientError => e
          return nil if e.code == 'invalid_grant'
          raise e
        end
      end
    end
  end
end
