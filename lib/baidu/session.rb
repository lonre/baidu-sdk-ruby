# encoding: UTF-8

module Baidu
  class Session
    # 用户身份验证和授权的凭证
    # @return [String]
    attr_accessor :access_token
    # 用于刷新 Access Token 的 Refresh Token，并不是所有应用都会返回该参数（10年的有效期）
    # @return [String]
    attr_accessor :refresh_token
    # Access Token 最终的访问范围，即用户实际授予的权限列表
    # @return [String]
    attr_accessor :scope
    # 基于 http 调用 Open API 时所需要的 Session Key
    # @return [String]
    attr_accessor :session_key
    # 基于 http 调用 Open API 时计算参数签名用的签名密钥
    # @return [String]
    attr_accessor :session_secret

    class << self
      # 根据 Hash 数据创建一个新的 +Session+ 实例
      # @param [Hash] hash 包含 Session 所需数据的 Hash
      # @return [Session]
      def from(hash)
        session = Session.new
        session.access_token   = hash[:access_token]
        session.refresh_token  = hash[:refresh_token]
        session.scope          = hash[:scope]
        session.session_key    = hash[:session_key]
        session.session_secret = hash[:session_secret]
        session
      end
    end
  end
end
