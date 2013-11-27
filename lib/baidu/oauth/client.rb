# encoding: UTF-8

require 'baidu/oauth/flow/code'
require 'baidu/oauth/flow/device'

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

      # @!method code_flow
      #   采用 Authorization Code 获取 Access Token 的授权验证流程
      #   @return [Flow::Code]
      # @!method device_flow
      #   采用 Device Code 获取 Access Token 的授权验证流程
      #   @return [Flow::Device]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/authorization Authorization Code
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/device Device
      [:code, :device].each do |flow|
        define_method("#{flow}_flow".to_sym) do
          Baidu::OAuth::Flow.const_get(flow.capitalize).new self
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
    end
  end
end
