# encoding: UTF-8

require 'baidu/oauth/flow/base'

module Baidu
  module OAuth
    module Flow

      # 采用Implicit Grant方式获取Access Token的授权验证流程又被称为User-Agent Flow，
      # 适用于所有无Server端配合的应用（由于应用往往位于一个User Agent里，如浏览器里面，
      # 因此这类应用在某些平台下又被称为Client-Side Application），如手机/桌面客户端程序、浏览器插件等，
      # 以及基于JavaScript等脚本客户端脚本语言实现的应用，他们的一个共同特点是，
      # 应用无法妥善保管其应用密钥（App Secret Key）
      #
      # @note 采用Implicit Grant方式获取Access Token时，不会返回Refresh Token。
      # @note
      #   为了保证安全性，建议应用从授权回调地址接收到Access Token之后，
      #   调用Access Token验证接口判断该Access Token是否对应自身的Api Key。
      #
      # @todo 验证接口
      # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/implicit Implicit Grant授权
      class Implicit < Base
        include Authable

        # 获取 Authorization URL
        #
        # @note
        #   为了加强安全性，会对跳转到该授权页面的Referer进行检测，
        #   要求Referer必须与开发者创建应用时注册的"网站地址"或者在“OAuth安全设置”中所填写的"根域名绑定"同域。
        #
        # @param [String] redirect_uri
        #   授权后要回调的URI，即接受Access Token的URI。
        #   如果用户在授权过程中取消授权，会回调该URI，并在URI末尾附上error=access_denied参数。
        #   对于无Web Server的应用，其值可以是“oob”，授权后会回调OAuth提供的一个默认页面。
        #   如果redirect_uri不为"oob"，则redirect_uri指向的页面必须与开发者在“OAuth安全设置”中所填写的"授权回调地址"相匹配。
        # @option params [String] :scope 以空格分隔的权限列表，若不传递此参数，代表请求用户的默认权限
        # @option params [String] :state
        #   用于保持请求和回调的状态，授权服务器在回调时（重定向用户浏览器到“redirect_uri”时），会在Fragment中原样回传该参数。
        # @option params [String] :display 登录和授权页面的展现样式，默认为“page”
        # @option params [Boolean] :force_login +true+ 表示加载登录页时强制用户输入用户名和口令，不会从cookie中读取百度用户的登陆状态
        # @option params [Boolean] :confirm_login +true+ 表示且百度用户已处于登陆状态，会提示是否使用已当前登陆用户对应用授权
        # @return [String]
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/implicit Implicit Grant授权
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/list 权限列表
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/set 页面设置
        # @see http://developer.baidu.com/wiki/index.php?title=docs/oauth/redirect 授权回调地址
        def authorize_url(redirect_uri, params={}); super end

        private

        def authorize_query
          { response_type: 'token', display: 'page' }
        end
      end
    end
  end
end
