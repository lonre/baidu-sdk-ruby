module Baidu
  module Configure
    # 申请创建应用后获取的 API Key
    # @return [String]
    attr_accessor :client_id

    # 申请创建应用后获取的 Secret Key
    # @return [String]
    attr_accessor :client_secret

    # 用来控制是否在终端输出调试信息，主要涉及网络请求部分（Net::HTTP）
    # @note 请勿在生产环境中打开
    # @return [Boolean] 默认为 false
    attr_accessor :debug

    # 通过 block 进行 API 配置
    #
    # @yield [c]
    # @yieldparam c [Configure]
    # @return [Configure]
    def config
      self.debug = false  # 默认 false
      yield self
      self
    end
  end
end
