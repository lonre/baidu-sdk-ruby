# encoding: UTF-8

module Baidu
  module OAuth
    module Flow

      # 所有授权流程基类
      class Base

        # 此授权流程对应的 OAuth Client 实例
        # @return [Baidu::OAuth::Client]
        attr_reader :client

        def initialize(client)
          @client = client
        end
      end

      # @private
      module Authable
        include Baidu::Support

        # Sub class must implement +authorize_query+ method
        def authorize_url(redirect_uri, params={})
          query = authorize_query.update params
          query.update({ client_id: self.client.client_id, redirect_uri: redirect_uri })
          query.update({ force_login: 1 })   if params[:force_login]
          query.update({ confirm_login: 1 }) if params[:confirm_login]
          Util.clean_params query
          uri = URI(self.client.site)
          uri.path  = Baidu::OAuth::AUTHORIZATION_ENDPOINT
          uri.query = Util.encode_params(query) unless Util.blank? query
          uri.to_s
        end
      end

      # @private
      module Tokenable

        # Sub class must implement +token_body+ method
        def get_token(code, redirect_uri=nil, params={})
          body = token_body.update params
          body.update({ client_id: self.client.client_id,
                        client_secret: self.client.client_secret,
                        redirect_uri: redirect_uri, code: code})
          rest = self.client.post Baidu::OAuth::TOKEN_ENDPOINT, nil, body
          return nil if rest.nil?
          Baidu::Session.from rest
        end
      end
    end
  end
end
