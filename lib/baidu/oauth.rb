require 'baidu/core'
require 'baidu/oauth/client'
require 'baidu/oauth/user_client'

module Baidu
  module OAuth
    SITE                   = 'https://openapi.baidu.com'
    BASE_PATH              = '/rest/2.0'
    AUTHORIZATION_ENDPOINT = '/oauth/2.0/authorize'
    TOKEN_ENDPOINT         = '/oauth/2.0/token'
    TOKEN_INFO_ENDPOINT    = '/oauth/2.0/tokeninfo'
    DEVICE_ENDPOINT        = '/oauth/2.0/device/code'
  end
end
