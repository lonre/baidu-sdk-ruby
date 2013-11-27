# encoding: UTF-8

module Baidu
  module Support
    module Request
      include Baidu::Support

      # 最多重定向次数
      MAX_REDIRECT_LIMIT = 10

      # 发送 GET 请求
      #
      # @param [String] path
      # @param [Hash] query 自动清理 value 为 nil 的数据
      # @option options [String] :site
      # @option options [Boolean] :raw  直接返回 response.body
      # @option options [Hash] :headers
      # @yield [segment] 可选，如果提供 block，则以流的方式获取内容
      def get(path, query={}, options={}, &block)
        url  = build_url path, query, options[:site]
        req = Net::HTTP::Get.new(url, options[:headers])
        if block_given?
          request(req) do |resp|
            resp.read_body &block
          end
        else
          request(req, nil, options[:raw])
        end
      end

      # 发送 POST 请求
      #
      # @param [String] path
      # @param [Hash] query 自动清理 value 为 nil 的数据
      # @param [Hash] body  自动清理 value 为 nil 的数据，可以包含响应 +#read+ 的对象，如：+File+
      # @option options [String] :site
      def post(path, query={}, body={}, options={})
        uri = build_url path, query, options[:site]
        Util.clean_params(body)
        if body.select{ |_, v| v.respond_to? :read }.empty?
          req = Net::HTTP::Post.new uri
          req.body = (body.empty? ? nil : Util.encode_params(body))
        else
          require 'net/http/post/multipart'
          body.each { |k, v| body[k] = UploadIO.new v, 'application/octet-stream' if v.respond_to? :read }
          req = Net::HTTP::Post::Multipart.new uri, body
        end
        request req
      end

      private

      def request(req, body=nil, raw=false, limit=0, &block)
        uri = URI(req.path)
        http = Net::HTTP.new uri.host, uri.port
        # trick for 1.9 support, just use req.uri for ruby version 2
        path_uri = URI(uri.path)
        path_uri.query = uri.query
        req.instance_variable_set(:@path, path_uri.to_s)
        # end trick
        http.set_debug_output $stdout if Baidu.debug
        http.use_ssl = uri.scheme == 'https'
        if http.use_ssl?
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.cert_store = OpenSSL::X509::Store.new
          http.cert_store.set_default_paths
          http.cert_store.add_file File.expand_path('../cacert.pem', __FILE__)
        end

        req['User-Agent'] = "UnofficialRubySDK/baidu-sdk/#{Baidu::VERSION}"

        if block_given?
          # To avoid read_body read called twice
          return http.request req, body, &block
        else
          resp = http.request req, body
          resp_body = resp.body

          # when raw, return quickly without JSON parse
          return resp_body if resp.is_a?(Net::HTTPSuccess) && raw

          resp_hash = begin
                        JSON.parse(resp_body, symbolize_names: true) unless resp_body.nil?
                      rescue
                        nil
                      end || {}

          case resp
          when Net::HTTPSuccess
            return resp_hash
          when Net::HTTPRedirection
            # Process redirection
            limit += 1
            return process_redirect resp['Location'], raw, limit
          end

          # error
          err = case resp
                when Net::HTTPUnauthorized then Baidu::Errors::AuthError
                when Net::HTTPClientError  then Baidu::Errors::ClientError
                when Net::HTTPServerError  then Baidu::Errors::ServerError
                else Baidu::Errors::Error
                end

          code = resp_hash.nil? ? resp.code : (resp_hash[:error_code] || resp_hash[:error])
          msg  = resp_hash.nil? ? resp.msg  : (resp_hash[:error_msg]  || resp_hash[:error_description])
          raise err.new(msg, code, resp)
        end
      end

      def build_url(path, query, site)
        uri = URI(site || @site)
        uri.path = path
        unless Util.blank? query
          Util.clean_params query
          uri.query = Util.encode_params(query)
        end
        uri.to_s
      end

      def process_redirect(url, raw, limit)
        raise Baidu::Errors::Error.new('Too many redirects') if limit > MAX_REDIRECT_LIMIT
        request(Net::HTTP::Get.new(url), nil, raw, limit)
      end
    end
  end
end
