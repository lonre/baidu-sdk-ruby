# encoding: UTF-8

require 'baidu/oauth/flow/base'

module Baidu
  module OAuth
    module Flow

      # 采用Client Credentials方式，即应用公钥、密钥方式获取Access Token，
      # 适用于任何类型应用，但通过它所获取的Access Token只能用于访问与用户无关的Open API，
      # 并且需要开发者提前向百度开放平台申请，成功对接后方能使用。
      # 对于应用而言，其流程只有一步，即直接获取Access Token。
      #
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/client Client Credentials授权
      class ClientCredentials < Base
        include Tokenable

        # 使用 Client Credentials 获取 Access Token
        #
        # @param [String] scope Access Token最终的访问范围，即用户实际授予的权限列表
        # @return [Baidu::Session]
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/client Client Credentials授权
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/overview Access Token生命周期
        def get_token(scope=nil)
          super(nil, nil, scope: scope)
        end

        private

        def token_body
          { grant_type: 'client_credentials' }
        end
      end
    end
  end
end
