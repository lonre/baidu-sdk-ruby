# encoding: UTF-8

require 'baidu/oauth/flow/base'

module Baidu
  module OAuth
    module Flow

      # 对设备应用而言，其流程由获取User Code和Device Code、引导用户去百度
      # 填写User Code并授权、以及通过Device Code获取Access Token这3步组成。
      #
      # @note 使用此授权流程，对于终端类型的应用也非常方便，同时还可以获取 Refresh Token
      #
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/device Device授权
      class Device < Base
        include Tokenable

        # 获取 User Code 和 Device Code
        # @example 返回的原始 JSON
        #   {
        #     "device_code": "a82hjs723h72h3a82hjs723h72h3vb",
        #     "user_code": "8sjiae3p",
        #     "verification_url": "https://openapi.baidu.com/oauth/2.0/device",
        #     "qrcode_url": "http://openapi.baidu.com/device/qrcode/6c6a8afee394f99e55eb25858/2c885vjk",
        #     "expires_in": 1800,
        #     "interval": 5
        #   }
        #
        #   :device_code      Device Code，设备需要保存，供下一步使用
        #   :user_code        User Code，设备需要展示给用户
        #   :verification_url 用户填写User Code并进行授权的url，设备需要展示给用户
        #   :qrcode_url       用于二维码登陆的Qr Code图片url，用户用智能终端扫描该二维码之后，
        #                     可直接进入步骤2的登陆授权页面
        #   :expires_in       Device Code/ Use Code的过期时间，单位为秒
        #   :interval         设备尝试获取Access Token的时间间隔，单位为秒，设备下一步会使用
        #
        # @param [String] scope 非必须参数，以空格分隔的权限列表
        # @return [Hash]
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/device Device授权
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表
        def user_and_device_code(scope=nil)
          query = authorize_query.update({ client_id: self.client.client_id })
          query[:scope] = scope unless scope.nil?
          self.client.get(Baidu::OAuth::DEVICE_ENDPOINT, query)
        end

        # 通过 Device Code 来获取 Access Token
        #
        # @param [String] code {#user_and_device_code} 所获得的 Device Code
        # @return [Baidu::Session]
        # @see #user_and_device_code
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/device Device授权
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/overview Access Token生命周期
        def get_token(code); super end

        private

        def authorize_query
          { response_type: 'device_code', display: nil }
        end

        def token_body
          { grant_type: 'device_token' }
        end
      end
    end
  end
end
