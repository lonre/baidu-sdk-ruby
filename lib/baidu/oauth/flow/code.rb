# encoding: UTF-8

require 'baidu/oauth/flow/base'

module Baidu
  module OAuth
    module Flow

      # 采用Authorization Code获取Access Token的授权验证流程又被称为Web Server Flow，
      # 适用于所有有Server端的应用，如Web/Wap站点、有Server端的手机/桌面客户端应用等。
      #
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/authorization Authorization Code授权
      class Code
        include Base

        # 通过 Device Code 来获取 Access Token
        #
        # @note 每一个 Authorization Code 的有效期为10分钟，并且只能使用一次，再次使用将无效。
        #
        # 如果用户在此页面同意授权，授权服务则将重定向用户浏览器到应用所指定的“redirect_uri”，
        # 并附带上表示授权服务所分配的 Authorization Code 的 +code+ 参数，以及 state 参数（如果请求authorization code时带了这个参数）。
        #
        # @param [String] code 所获得的 Authorization Code (redirect_uri 附带的 code 参数)
        # @return [Baidu::Session]
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/device 通过Device Code获取Access Token
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/overview Access Token生命周期
        def get_token(code, redirect_uri); super end

        # 获取 Authorization URL
        # @param [String] redirect_uri 授权后要回调的URI，即接收Authorization Code的URI。
        #                              如果用户在授权过程中取消授权，会回调该URI，并在URI末尾附上error=access_denied参数。
        #                              对于无Web Server的应用，其值可以是“oob”，此时用户同意授权后，
        #                              授权服务会将Authorization Code直接显示在响应页面的页面中及页面title中。
        #                              非“oob”值的redirect_uri按照如下规则进行匹配：
        #                              （1）如果开发者在“授权安全设置”中配置了“授权回调地址”，
        #                              则redirect_uri必须与“授权回调地址”中的某一个相匹配；
        #                              （2）如果未配置“授权回调地址”，redirect_uri所在域名必须与开发者注册应用时
        #                              所提供的网站根域名列表或应用的站点地址（如果根域名列表没填写）的域名相匹配。
        # @option params [String] :scope 以空格分隔的权限列表，若不传递此参数，代表请求用户的默认权限
        # @option params [String] :state 用于保持请求和回调的状态，授权服务器在回调时（重定向用户浏览器到“redirect_uri”时），
        #                                会在Query Parameter中原样回传该参数。OAuth2.0标准协议建议，利用state参数来防止CSRF攻击
        # @option params [String] :display 登录和授权页面的展现样式，默认为“page”
        # @option params [Boolean] :force_login +true+ 表示加载登录页时强制用户输入用户名和口令，不会从cookie中读取百度用户的登陆状态
        # @option params [Boolean] :confirm_login +true+ 表示且百度用户已处于登陆状态，会提示是否使用已当前登陆用户对应用授权
        # @return [String]
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/set 页面设置
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/redirect 授权回调地址
        def authorize_url(redirect_uri, params={})
          opts = {}.update(params)
          opts.update({ force_login: 1 })   if params[:force_login]
          opts.update({ confirm_login: 1 }) if params[:confirm_login]
          super redirect_uri, opts
        end

        private

        def authorize_query
          { response_type: 'code', display: 'page' }
        end

        def token_body
          { grant_type: 'authorization_code' }
        end
      end
    end
  end
end
