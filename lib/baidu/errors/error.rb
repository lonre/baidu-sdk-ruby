module Baidu
  module Errors
    class Error < StandardError
      attr_reader :msg, :code, :response

      def initialize(msg, code=nil, response=nil)
        @msg, @code, @response = msg, code, response
      end

      def to_s
        arr = %w[Error]
        arr << "code: #{code}" unless code.nil?
        arr << "msg: #{msg}"   unless msg.nil?
        arr.join(' ')
      end
    end

    class AuthError < Error; end
    class ClientError < Error; end
    class ServerError < Error; end
  end
end
