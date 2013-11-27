require 'baidu/core'
require 'baidu/pcs/client'

module Baidu

  module PCS
    SITE             = 'https://pcs.baidu.com'
    UPLOAD_SITE      = 'https://c.pcs.baidu.com'
    DOWNLOAD_SITE    = 'https://d.pcs.baidu.com'
    BASE_PATH        = '/rest/2.0/pcs'
    APPS_PATH_PREFIX = '/apps'
  end

  module Configure
    # 全局配置 PCS 的文件目录
    # @return [String]
    attr_accessor :pcs_dir_name
  end
end
