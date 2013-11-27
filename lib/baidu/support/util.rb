# encoding: UTF-8

module Baidu
  module Support
    module Util
      class << self
        # Check whether +obj+ is blank or not
        # @example
        #   blank?('  ')  #true
        #   blank?('i ')  #false
        #   blank?(nil)   #true
        #   blank?(true)  #false
        #   blank?(false) #true
        #   blank?({})    #true
        #
        # @param [Object] obj
        def blank?(obj)
          case obj
          when String     then /[^[:space:]]/ !~ obj
          when NilClass   then true
          when TrueClass  then false
          when FalseClass then true
          else obj.respond_to?(:empty?) ? obj.empty? : !obj
          end
        end

        # Encode params to www form style
        # @example
        #   encode_params({first: 'Lonre', last: 'Wang'})
        #   => 'first=Lonre&last=Wang'
        # @param [Hash] params
        # @return [String]
        def encode_params(params)
          raise ArgumentError, 'require Hash instance' unless params.is_a? Hash
          URI::encode_www_form params
        end

        # Delete object which value is +nil+ from params
        # @example
        #   clean_params({first: 'Lonre', middle: nil, last: 'Wang'})
        #   => {first: 'Lonre', last: 'Wang'}
        # @param [Hash] params
        # @return [Hash]
        def clean_params(params)
          raise ArgumentError, 'require Hash instance' unless params.is_a? Hash
          unless blank? params
            params.delete_if { |k, v| v.nil? }
          end
        end

        # Change +"\\ ? | " > < : "*+ to +"_"+, multi "/" to one "/"
        # @example
        #   edit_path(" .hello///path<f:aa/go.zip. ")
        #   => "hello/path_f_aa/go.zip"
        # @return [String]
        def edit_path(path)
          return nil if path.nil?
          path = path.gsub(/\/+/, '/')
          path = path.gsub(/\A[\s\.]*/, '')
          path = path.gsub(/[\s\.]*\z/, '')
          path = path.gsub(/[\\\|\?"><:\*]/, '_')
          path
        end
      end
    end
  end
end
