# encoding: UTF-8

module Baidu
  module PCS

    # Client 类封装实现了 Baidu PCS 的文件API，主要包括文件上传、下载、拷贝、删除、搜索、断点续传及缩略图等功能。
    #
    # 本文档多数内容取自 {http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list 文件API列表}，
    # 使用本 API 之前请先参考 Baidu PCS {http://developer.baidu.com/wiki/index.php?title=docs/pcs/guide/overview 开发指南}，
    # 准备好相应环境。
    # @example
    #   require 'baidu/pcs'
    #
    #   #全局配置，如已在其他地方配置过，可以忽略
    #   Baidu.config do |c|
    #     # ...
    #     c.pcs_dir_name  = 'notes'  # 可选，如此处未做配置，那么实例化 Client 时必须指定 dir_name
    #     # ...
    #   end
    #
    #   # 用户授权完成之后获取的 access token
    #   access_token = 'xxxxxxxxxxxxxxxxxxxxxxxxx'
    #   # 使用全局配置 pcs_dir_name 作为文件目录
    #   client = Baidu::PCS::Client.new(access_token)
    #   # 不使用全局配置 pcs_dir_name
    #   # client = Baidu::PCS::Client.new(access_token, 'notes')
    #
    #   File.open('/opt/ubuntu-12.04.3-server-amd64.iso', 'r') do |f|
    #     result = client.upload(f)
    #     # result 为 Hash 实例，是直接根据 Baidu REST API 返回的 JSON 转换而来
    #     # 具体键值及意义可参看各方法中 “返回的原始 JSON” 部分
    #     puts result[:path]  # 输出上传后文件的保存路径
    #     puts result[:size]  # 输出上传的文件大小
    #     puts result[:md5]   # 输出上传的文件 md5 签名
    #   end
    #
    class Client
      include Baidu::Support::Request

      # 创建一个 +Baidu::PCS::Client+ 文件API 实例，通过此实例可以执行 文件API 调用
      # @overload initialize(access_token, dir_name=Baidu.pcs_dir_name)
      #   @param access_token [String] 通过 Baidu OAuth API 获得的 Access Token
      #   @param dir_name     [String] 开通 PCS API 权限时，填写的文件目录。如果未设置此参数，则使用全局配置
      #
      # @overload initialize(session, dir_name=Baidu.pcs_dir_name)
      #   @param session  [Baidu::Session] 通过 Baidu OAuth API 获得的 Session
      #   @param dir_name [String] 开通 PCS API 权限时，填写的文件目录。如果未设置此参数，则使用全局配置
      #
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/guide/api_approve 开通PCS API权限
      def initialize(access_token_or_session, dir_name=Baidu.pcs_dir_name)
        @dir_name = dir_name
        @access_token = case access_token_or_session
                        when String then access_token_or_session
                        when Baidu::Session then access_token_or_session.access_token
                        end
        raise ArgumentError, 'dir_name must not be blank' if Util.blank? @dir_name
        raise ArgumentError, 'access_token must not be blank' if Util.blank? @access_token
        @site = Baidu::PCS::SITE
        @dir_path = "#{APPS_PATH_PREFIX}/#{@dir_name}"
      end

      # @!group 1 基本功能

      # 空间配额信息
      #
      # 获取当前用户空间配额信息
      #
      # @example 返回的原始 JSON
      #   {"quota":15000000000,"used":5221166,"request_id":4043312634}
      #
      #   :quota 空间配额，单位为字节
      #   :used  已使用空间大小，单位为字节
      #
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E7.A9.BA.E9.97.B4.E9.85.8D.E9.A2.9D.E4.BF.A1.E6.81.AF 空间配额信息
      def quota
        get "#{BASE_PATH}/quota", base_query('info')
      end

      # 上传单个文件
      #
      # @note 百度PCS服务目前支持最大2G的单个文件上传
      # @note 文件大小超过 128MB 时，自动启用文件分块上传；
      #       如果不想启用文件分块上传，可以通过 +block_upload: false+ 来关闭
      #
      # @example
      #   File.open('/opt/ubuntu-12.04.3-server-amd64.iso', 'r') do |f|
      #     c.upload(f, block_upload: true)
      #   end
      #
      # @example 返回的原始 JSON
      #   {
      #     "fs_id": 3916799999,
      #     "path": "/apps/album/1.png",
      #     "ctime": 1384493574,
      #     "mtime": 1384493574,
      #     "md5": "6c37219ba0d3dfdfa95ff6912e2c42b9",
      #     "size": 4914,
      #     "request_id": 3036629135
      #   }
      #
      #   :fs_id 文件在PCS的临时唯一标识ID
      #   :path  该文件的绝对路径
      #   :ctime 文件创建时间
      #   :mtime 文件修改时间
      #   :md5   文件的md5签名
      #   :size  文件字节大小
      #
      # @param file [File]   待上传的文件
      # @option options [String]  :path 上传文件路径，含上传的文件名称（相对于应用根目录），默认为 +file+ 的文件名
      # @option options [Boolean] :overwrite
      #                  +true+:  表示覆盖同名文件，
      #                  +false+: 表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”，
      #                  默认为 +false+
      # @option options [Boolean] :block_upload  对文件分块上传，仅当 +file+ 大小超过 8MB 时，此设置有效；
      #                                          分块大小取决于文件大小，4GB 以下文件分块大小为 4MB
      # @option options [Fixnum]  :retry_times   <b>分块上传时</b>，出错自动重试次数，默认 5
      # @option options [Fixnum]  :retry_waitsec <b>分块上传时</b>，出错自动重试暂停秒数，默认 30
      # @return [Hash]
      # @see #upload_block
      # @see #create_super_file
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E4.B8.8A.E4.BC.A0.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6 上传单个文件
      def upload(file, options={})
        raise ArgumentError, 'file must be an instance of File' unless file.instance_of? File
        path = options[:path] || File.basename(file)
        size = file.size
        if (options[:block_upload] && size >= 4*1024*1024*2) ||  # at least 2 blocks
           (options[:block_upload].nil? && size >= 128*1024*1024)
          block_size = 4*1024*1024
          while block_size * 1024 < size  # at most 1024 blocks1
            block_size *= 2
          end
          offset, block_list = 0, []
          max_retry_times = options[:retry_times]   || 5
          retry_waitsec   = options[:retry_waitsec] || 30
          loop do
            with_retries(max_retry_times, retry_waitsec) do
              rest = upload_block IO.binread(file, block_size, offset)
              block_list << rest[:md5]
            end
            offset += block_size
            break if offset >= size
          end
          with_retries(max_retry_times, retry_waitsec) do
            create_super_file block_list, path, options[:overwrite]
          end
        else
          raise IOError, 'file is too large (larger than 2G)' if size > 2*1024*1024*1024
          query = build_upload_query 'upload', path, options[:overwrite]
          post "#{BASE_PATH}/file", query, { file: file }, site: Baidu::PCS::UPLOAD_SITE
        end
      end

      # 上传分片文件
      #
      # @note 百度PCS服务支持每次直接上传最大2G的单个文件。
      #       如需支持上传超大文件（>2G），则可以通过组合调用分片文件上传方法和合并分片文件方法实现：
      #         首先，将超大文件分割为2G以内的单文件，并调用 {#upload_block} 将分片文件依次上传；
      #         其次，调用 {#create_super_file} ，完成分片文件的重组。
      #       除此之外，如果应用中需要支持断点续传的功能，也可以通过分片上传文件并调用 {#create_super_file} 的方式实现。
      #
      # @example 返回的原始 JSON
      #   {"md5":"a7619410bca74850f985e488c9a0d51e","request_id":3238563823}
      #
      #   :md5 上传内容的md5签名
      #
      # @param data [String] 上传的内容
      # @return [Hash]
      # @see #create_super_file
      # @see #upload
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E5.88.86.E7.89.87.E4.B8.8A.E4.BC.A0.E2.80.94.E6.96.87.E4.BB.B6.E5.88.86.E7.89.87.E5.8F.8A.E4.B8.8A.E4.BC.A0 文件分片及上传
      def upload_block(data)
        query = build_upload_query 'upload', nil, nil, true
        post "#{BASE_PATH}/file", query, { file: StringIO.new(data) }, site: Baidu::PCS::UPLOAD_SITE
      end

      # 合并分片文件
      #
      # 与分片文件上传 {#upload_block} 方法配合使用，可实现超大文件（>2G）上传，同时也可用于断点续传的场景
      #
      # @example 返回的原始 JSON
      #   {
      #     "path": "/apps/album/1.png",
      #     "size": 6844,
      #     "ctime": 1331197101,
      #     "mtime": 1331197101,
      #     "md5": "baa7c379639b74e9bf98c807498e1b64",
      #     "fs_id": 1548308694,
      #     "request_id": 4043313276
      #   }
      #
      #   :path  该文件的绝对路径
      #   :size  文件字节大小
      #   :ctime 文件创建时间
      #   :mtime 文件修改时间
      #   :md5   文件的md5签名
      #   :fs_id 文件在PCS的临时唯一标识ID
      #
      # @param block_list [Array<String>] 数组，数组的取值为子文件内容的MD5；子文件至少2个，最多1024个
      # @param path [String] 上传文件路径（含上传的文件名称）
      # @param overwrite [Boolean]
      #                  +true+:  表示覆盖同名文件
      #                  +false+: 表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”
      # @return [Hash]
      # @see #upload_block
      # @see #upload
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E5.88.86.E7.89.87.E4.B8.8A.E4.BC.A0.E2.80.94.E5.90.88.E5.B9.B6.E5.88.86.E7.89.87.E6.96.87.E4.BB.B6 合并分片文件
      def create_super_file(block_list, path, overwrite=false)
        raise ArgumentError, 'block_list must be Array'           unless block_list.instance_of? Array
        raise ArgumentError, 'block_list size must be in 2..1024' unless block_list.length.between? 2, 1024
        query = build_upload_query 'createsuperfile', path, overwrite
        param = { block_list: block_list }
        post "#{BASE_PATH}/file", query, param: JSON.dump(param)
      end

      # 下载单个文件
      #
      # Download 接口支持 HTTP 协议标准 range 定义，通过指定 range 的取值可以实现断点下载功能。
      #
      # @example 下载文件第 101 - 200 字节之间的内容
      #   File.open('logo.part2.png', 'w') do |f|
      #     f.write client.download('logo.png', begin: 100, end: 199)
      #   end
      #
      # @overload download(path, options={})
      #   适合下载小文件，简单直接
      #   @note 下载大文件会占用过多的内存, 请使用 block 方法 #download(path, &block)
      #   @example
      #     File.open('logo.png', 'w') do |f|
      #       f.write client.download('logo.png')
      #     end
      #
      #   @param path [String] 下载文件路径，路径相对于应用目录，从应用根目录起计算
      #   @option options [Fixnum] :begin 断点下载的开始字节索引
      #   @option options [Fixnum] :end   断点下载的结束字节索引
      #   @return [String] 直接返回文件内容
      #
      # @overload download(path, options={}, &block)
      #   针对下载大文件优化的方法
      #   @example
      #     File.open('ubuntu.iso', 'w') do |f|
      #       client.download('ubuntu-12.04.3-server-amd64.iso') do |segment|
      #         f.write segment
      #       end
      #     end
      #
      #   @param path [String] 下载文件路径，路径相对于应用目录，从应用根目录起计算
      #   @option options [Fixnum] :begin 断点下载的开始字节索引
      #   @option options [Fixnum] :end   断点下载的结束字节索引
      #   @yield [segment] 下载内容将以片段的方式提供
      #   @return [void]
      #
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E4.B8.8B.E8.BD.BD.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6 下载单个文件
      def download(path, options={}, &block)
        site = Baidu::PCS::DOWNLOAD_SITE
        query = { path: build_path(path) }.update(base_query 'download')
        headers = if options[:begin] || options[:end]
                    range = "#{options[:begin] || 0}-#{options[:end]}"
                    { Range: "bytes=#{range}" }
                  end
        if block_given?
          get "#{BASE_PATH}/file", query, site: site, headers: headers, &block
        else
          get "#{BASE_PATH}/file", query, site: site, headers: headers, raw: true
        end
      end

      # 创建目录
      #
      # 为当前用户创建一个目录
      #
      # @example 返回的原始 JSON
      #  {
      #    "fs_id": 1636599174,
      #    "path": "/apps/yunfom/music",
      #    "ctime": 1331183814,
      #    "mtime": 1331183814,
      #    "request_id": 4043312656
      #  }
      #
      #  :fs_id 目录在PCS的临时唯一标识id
      #  :path  该目录的绝对路径
      #  :ctime 目录创建时间
      #  :mtime 目录修改时间
      #
      # @param path [String] 需要创建的目录，相对于应用根目录
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E5.88.9B.E5.BB.BA.E7.9B.AE.E5.BD.95 创建目录
      def mkdir(path)
        query = { path: build_path(path, true) }
        post "#{BASE_PATH}/file", query.update(base_query 'mkdir')
      end

      # 单个或批量获取文件/目录的元信息
      #
      # @example 返回的原始 JSON
      #   {
      #     "list": [
      #       {
      #         "fs_id": 3528850315,
      #         "path": "/apps/album/music/hello",
      #         "ctime": 1331184269,
      #         "mtime": 1331184269,
      #         "block_list": [
      #           "59ca0efa9f5633cb0371bbc0355478d8"
      #         ],
      #         "size": 13,
      #         "isdir": 1
      #       }
      #     ],
      #     "request_id": 4043312678
      #   }
      #
      #   :fs_id       文件或目录在PCS的临时唯一标识ID
      #   :path        文件或目录的绝对路径
      #   :ctime       文件或目录的创建时间
      #   :mtime       文件或目录的最后修改时间
      #   :block_list  文件所有分片的md5数组JSON字符串
      #   :size        文件大小（byte）
      #   :isdir       是否是目录的标识符：“0”为文件，“1”为目录
      #   :ifhassubdir 是否含有子目录的标识符：“0”表示没有子目录，“1”表示有子目录
      #
      # @overload meta(path)
      #   获取单个文件或目录的元信息
      #   @param path [String] 文件或目录路径，相对于应用根目录
      #   @return [Hash]
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E8.8E.B7.E5.8F.96.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95.E7.9A.84.E5.85.83.E4.BF.A1.E6.81.AF 获取单个文件/目录的元信息
      #
      # @overload meta(paths)
      #   批量获取文件或目录的元信息
      #   @param paths [Array<String>] 文件或目录路径，相对于应用根目录
      #   @return [Hash]
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.89.B9.E9.87.8F.E8.8E.B7.E5.8F.96.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95.E7.9A.84.E5.85.83.E4.BF.A1.E6.81.AF 批量获取文件/目录的元信息
      #
      # @return [Hash]
      def meta(path)
        meta_or_delete :meta, path
      end

      # 获取目录下的文件列表
      #
      # @example 调用示例
      #   client.list('apitest/movies', order: 'asc', by: 'time', limit: '2-10')
      #
      # @example 返回的原始 JSON
      #   {
      #     "list": [
      #       {
      #         "fs_id": 703525418,
      #         "path": "/apps/Backups/apitest/movies/1.mkv",
      #         "ctime": 1377136220,
      #         "mtime": 1384493344,
      #         "md5": "6366d2a234e8139c63dab707ec4569c3",
      #         "size": 74818037,
      #         "isdir": 0
      #       }
      #     ],
      #     "request_id": 4043312670
      #   }
      #
      #   :fs_id 文件或目录在PCS的临时唯一标识id
      #   :path  文件或目录的绝对路径
      #   :ctime 文件或目录的创建时间
      #   :mtime 文件或目录的最后修改时间
      #   :md5   文件的md5值
      #   :size  文件大小（byte）
      #   :isdir 是否是目录的标识符：“0”为文件，“1”为目录
      #
      # @param path  [String] 需要list的目录（相对于应用的根目录）
      #
      # @option options [String] :by    排序字段，缺省根据文件名排序：
      #                                 +time+（修改时间），
      #                                 +name+（文件名），
      #                                 +size+（大小，注意目录无大小）
      # @option options [String] :order “+asc+”或“+desc+”，缺省采用降序排序：
      #                                 +asc+（升序），
      #                                 +desc+（降序）
      # @option options [String] :limit 返回条目控制，参数格式为：n1-n2。
      #                                 返回结果集的[n1, n2)之间的条目，缺省返回所有条目；n1从0开始
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E8.8E.B7.E5.8F.96.E7.9B.AE.E5.BD.95.E4.B8.8B.E7.9A.84.E6.96.87.E4.BB.B6.E5.88.97.E8.A1.A8 获取目录下的文件列表
      def list(path, options={})
        query = { path: build_path(path) }
        query[:by]    = options[:by]    || 'name'
        query[:order] = options[:order] || 'desc'
        query[:limit] = options[:limit]
        get "#{BASE_PATH}/file", query.update(base_query 'list')
      end

      # 单个或批量移动文件/目录
      #
      # @example 返回的原始 JSON
      #   {
      #     "extra": {
      #       "list": [
      #         {
      #           "to": "/apps/album/test2/2.jpg",
      #           "from": "/apps/album/test1/1.jpg"
      #         }
      #       ]
      #     },
      #     "request_id": 2298812844
      #   }
      #
      #   :from 执行move操作成功的源文件地址
      #   :to   执行move操作成功的目标文件地址
      #
      # @overload move(from, to)
      #   移动单个文件/目录
      #   @note 调用move接口时，目标文件的名称如果和源文件不相同，将会在move操作时对文件进行重命名
      #   @param from [String] 源文件地址（包括文件名，相对于应用根目录）
      #   @param to   [String] 目标文件地址（包括文件名，相对于应用根目录）
      #   @return [Hash] 如果move操作执行成功，那么response会返回执行成功的from/to列表
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E7.A7.BB.E5.8A.A8.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95 移动单个文件/目录
      #
      # @overload move(froms, tos)
      #   批量移动文件/目录
      #   @note 批量执行move操作时，move接口一次对请求参数中的每个from/to进行操作；执行失败就会退出，成功就继续，返回执行成功的from/to列表
      #   @param froms [Array<String>] 源文件地址（包括文件名，相对于应用根目录）
      #   @param tos   [Array<String>] 目标文件地址（包括文件名，相对于应用根目录）
      #   @return [Hash] 返回参数extra由list数组组成，list数组的两个元素分别是“from”和“to”，代表move操作的源地址和目的地址
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.89.B9.E9.87.8F.E7.A7.BB.E5.8A.A8.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95 批量移动文件/目录
      #
      # @return [Hash]
      def move(from, to)
        move_or_copy :move, from, to
      end

      # 单个或批量拷贝文件/目录
      #
      # @example 返回的原始 JSON
      #   {
      #     "extra": {
      #       "list": [
      #         {
      #           "to": "/apps/album/test2/6.jpg",
      #           "from": "/apps/album/test1/6.jpg"
      #         }
      #       ]
      #     },
      #     "request_id": 2298812844
      #   }
      #
      #   :from 执行copy操作成功的源文件地址
      #   :to   执行copy操作成功的目标文件地址
      #
      # @overload copy(from, to)
      #   拷贝单个文件/目录
      #   @note move操作后，源文件被移动至目标地址；copy操作则会保留原文件
      #   @param from [String] 源文件地址（包括文件名，相对于应用根目录）
      #   @param to   [String] 目标文件地址（包括文件名，相对于应用根目录）
      #   @return [Hash] 如果copy操作执行成功，那么response会返回执行成功的from/to列表
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.8B.B7.E8.B4.9D.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95 拷贝单个文件/目录
      #
      # @overload copy(froms, tos)
      #   批量拷贝文件/目录
      #   @note 批量执行copy操作时，copy接口一次对请求参数中的每个from/to进行操作；执行失败就会退出，成功就继续，返回执行成功的from/to列表
      #   @param froms [Array<String>] 源文件地址（相对于应用根目录）
      #   @param tos   [Array<String>] 目标文件地址（相对于应用根目录）
      #   @return [Hash] 返回参数extra由list数组组成，list数组的两个元素分别是“from”和“to”，代表copy操作的源地址和目的地址
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.89.B9.E9.87.8F.E6.8B.B7.E8.B4.9D.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95 批量拷贝文件/目录
      #
      # @return [Hash]
      def copy(from, to)
        move_or_copy :copy, from, to
      end

      # 单个或批量删除文件/目录
      # @note 文件/目录删除后默认临时存放在回收站内，删除文件或目录的临时存放不占用用户的空间配额；
      #         存放有效期为10天，10天内可还原回原路径下，10天后则永久删除
      #
      # @example 返回的原始 JSON
      #   {"request_id":4043312866}
      #
      # @overload delete(path)
      #   删除单个文件/目录
      #   @param path [String] 需要删除的文件或者目录路径
      #   @return [Hash]
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E5.88.A0.E9.99.A4.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95 删除单个文件/目录
      #
      # @overload delete(paths)
      #   批量删除文件/目录
      #   @param paths [Array<String>] 需要删除的文件或者目录路径
      #   @return [Hash]
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.89.B9.E9.87.8F.E5.88.A0.E9.99.A4.E6.96.87.E4.BB.B6.2F.E7.9B.AE.E5.BD.95 批量删除文件/目录
      #
      # @return [Hash]
      def delete(path)
        meta_or_delete :delete, path
      end

      # 按文件名搜索文件
      # @note 不支持查找目录
      #
      # @example 返回的原始 JSON
      #   {
      #     "list": [
      #       {
      #         "fs_id": 3528850315,
      #         "path": "/apps/album/music/hello",
      #         "ctime": 1331184269,
      #         "mtime": 1331184269,
      #         "block_list": [
      #           "59ca0efa9f5633cb0371bbc0355478d8"
      #         ],
      #         "size": 13,
      #         "isdir": 0
      #       }
      #     ],
      #     "request_id": 4043312670
      #   }
      #
      #   :fs_id 目录在PCS的临时唯一标识ID。
      #   :path  该目录的绝对路径。
      #   :ctime 文件服务器创建时间。
      #   :mtime 文件服务器修改时间。
      #   :md5   文件的md5值。
      #   :size  文件大小（byte）。
      #   :isdir 是否是目录的标识符：“0”为文件，“1”为目录
      #
      # @param path [String]  需要检索的目录（相对于应用根目录）
      # @param wd   [String]  关键词
      # @param re   [Boolean] 是否递归：+true+ 表示递归，+false+ 表示不递归
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.90.9C.E7.B4.A2 搜索
      def search(path, wd, re=false)
        path = build_path path
        query = { path: path, wd: wd, re: (re ? 1 : 0) }
        get "#{BASE_PATH}/file", query.update(base_query 'search')
      end

      # @!endgroup

      # @!group 2 高级功能

      # 获取指定图片文件的缩略图
      # @note 限制条件：
      #       原图大小(0, 10M]；
      #       原图类型: jpg、jpeg、bmp、gif、png；
      #       目标图类型和原图的类型有关；例如：原图是gif图片，则缩略后也为gif图片
      # @param path    [String] 源图片的路径（相对于应用根目录）
      # @param width   [Fixnum] 指定缩略图的宽度，取值范围为(0,1600]
      # @param height  [Fixnum] 指定缩略图的高度，取值范围为(0,1600]
      # @param quality [Fixnum] 缩略图的质量，默认为“100”，取值范围(0,100]
      #
      # @overload thumbnail(path, width, height, quality=100)
      #   @example
      #     File.open('logo_120.png', 'w') do |f|
      #       f.write client.thumbnail('logo.png', 120, 120)
      #     end
      #   @return [String] 缩略图文件内容
      #
      # @overload thumbnail(path, width, height, quality=100, &block)
      #   使用 block 方式，减少内存占用率
      #   @example
      #     File.open('logo_1600.png', 'w') do |f|
      #       client.thumbnail('logo.png', 1600, 1600) do |segment|
      #         f.write segment
      #       end
      #     end
      #   @yield  [segment] 内容将以片段的方式提供
      #   @return [void]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E7.BC.A9.E7.95.A5.E5.9B.BE 缩略图
      # @see #download
      def thumbnail(path, width, height, quality=100, &block)
        path = build_path path
        query = { path: path, width: width, height: height, quality: quality }.update base_query('generate')
        if block_given?
          get "#{BASE_PATH}/thumbnail", query, &block
        else
          get "#{BASE_PATH}/thumbnail", query, raw: true
        end
      end

      # 文件增量更新操作查询
      # @note 本接口有数秒延迟，但保证返回结果为最终一致
      #
      # @example 返回的原始 JSON
      #   {
      #     "entries": {
      #       "/apps/album/6.png": {
      #         "fs_id": 3858723392,
      #         "path": "/apps/album/6.png",
      #         "size": 4914,
      #         "isdir": 0,
      #         "isdelete": 0,
      #         "revision": 0,
      #         "md5": "6c37219ba0d3dfdfa95ff6912e2c42b9",
      #         "mtime": 1384526979,
      #         "ctime": 1384526979
      #       },
      #       "/apps/ablum/logo.png": {
      #         "fs_id": 3866920660,
      #         "path": "/apps/album/logo.png",
      #         "size": 4914,
      #         "isdir": 0,
      #         "isdelete": 0,
      #         "revision": 0,
      #         "md5": "6c37219ba0d3dfdfa95ff6912e2c42b9",
      #         "mtime": 1384486230,
      #         "ctime": 1384021638
      #       }
      #     },
      #     "has_more": true,
      #     "reset": true,
      #     "cursor": "MxKx6UPie%2F9WzBkwALPrVWQlyxlmK0LgHG8zutwXp8oyC%2F2BQ%3D%3D...",
      #     "request_id": 3355443548
      #   }
      #
      #   :entries  k-v形式的列表，分为以下两种形式：
      #               1. key为path，value为path对应的meta值，meta中isdelete=0为更新操作
      #                    如果path为文件，则更新path对应的文件；
      #                    如果path为目录，则更新path对应的目录信息，但不更新path下的文件。
      #               2. key为path，value为path删除的meta信息，meta中“isdelete!=0”为删除操作
      #                    isdelete=1 该文件被永久删除；
      #                    isdelete=-1 该文件被放置进回收站；
      #                    如果path为文件，则删除该path对应的文件；
      #                    如果path为目录，则删除该path对应的目录和目录下的所有子目录和文件；
      #                    如果path在本地没有任何记录，则跳过本删除操作。
      #   :has_more True：  本次调用diff接口，增量更新结果服务器端无法一次性返回，客户端可以立刻再调用一次diff接口获取剩余结果；
      #             False： 截止当前的增量更新结果已经全部返回，客户端可以等待一段时间（1-2分钟）之后再diff一次查看是否有更新。
      #   :reset    True： 服务器通知客户端，服务器端将按时间排序从第一条开始向客户端返回一份完整的数据列表；
      #             False：返回上次请求返回cursor之后的增量更新结果。
      #   :cursor   用于下一次调用diff接口时传入的断点参数。
      #
      # @param cursor [String] 用于标记更新断点：
      #                          首次调用cursor=null；
      #                          非首次调用，使用最后一次调用diff接口的返回结果中的cursor
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E5.A2.9E.E9.87.8F.E6.9B.B4.E6.96.B0.E6.9F.A5.E8.AF.A2 增量更新查询
      def diff(cursor='null')
        query = { cursor: cursor }
        get "#{BASE_PATH}/file", query.update(base_query 'diff')
      end

      # 视频转码
      #
      # 对视频文件进行转码，实现实时观看视频功能。可下载支持HLS/M3U8的媒体云播放器SDK配合使用。
      # @note 目前这个接口支持的源文件格式如下：m3u8/m3u/asf/avi/flv/gif/mkv/mov/mp4/m4a/3gp/3g2/mj2/mpeg/ts/rm/rmvb/webm
      # @param path [String] 需要下载的视频文件路径，需含源文件的文件名（相对于应用根目录）
      # @param type [String] 目前支持以下格式：M3U8_320_240、M3U8_480_224、M3U8_480_360、M3U8_640_480和M3U8_854_480
      # @return [String] 直接返回文件内容（在线播放的 URL 地址清单）
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E8.A7.86.E9.A2.91.E8.BD.AC.E7.A0.81 视频转码
      def streaming(path, type, &block)
        path = build_path path
        query = { path: path, type: type }.update base_query('streaming')
        if block_given?
          get "#{BASE_PATH}/file", query, &block
        else
          get "#{BASE_PATH}/file", query, raw: true
        end
      end

      # 获取流式文件列表
      #
      # 以视频、音频、图片及文档四种类型的视图获取所创建应用程序下的文件列表。
      #
      # @example 返回的原始 JSON
      #   {
      #     "total": 13,
      #     "start": 0,
      #     "limit": 1,
      #     "list": [
      #       {
      #         "path": "/apps/album/1.jpg",
      #         "size": 372121,
      #         "ctime": 1234567890,
      #         "mtime": 1234567890,
      #         "md5": "cb123afcc12453543ef",
      #         "fs_id": 12345,
      #         "isdir": 0
      #       }
      #     ]
      #   }
      #
      #   :total      文件总数
      #   :start      起始数
      #   :limit      获取数
      #   :path       获取流式文件的绝对路径
      #   :block_list 分片MD5列表
      #   :size       流式文件的文件大小（byte）
      #   :mtime      流式文件在服务器上的修改时间
      #   :ctime      流式文件在服务器上的创建时间
      #   :fs_id      流式文件在PCS中的唯一标识ID
      #   :isdir      “0”文件，“1”目录
      #
      # @param type  [String] 类型分为video、audio、image及doc四种
      # @option options [Fixnum] :start       返回条目控制起始值，默认为0
      # @option options [Fixnum] :limit       返回条目控制长度，默认为1000
      # @option options [String] :filter_path 需要过滤的前缀路径，如：/apps/album
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E8.8E.B7.E5.8F.96.E6.B5.81.E5.BC.8F.E6.96.87.E4.BB.B6.E5.88.97.E8.A1.A8 获取流式文件列表
      def stream_list(type, options={})
        query = { type: type }.update options
        get "#{BASE_PATH}/stream", query.update(base_query 'list')
      end

      # 秒传文件
      # @note 被秒传文件必须大于256KB（即 256*1024 B）；校验段为文件的前256KB，秒传接口需要提供校验段的MD5。
      # @note 非强一致接口，上传后请等待1秒后再读取
      #
      # @example 返回的原始 JSON
      #   {
      #     "path": "/apps/album/1.jpg",
      #     "size": 372121,
      #     "ctime": 1234567890,
      #     "mtime": 1234567890,
      #     "md5": "cb123afcc12453543ef",
      #     "fs_id": 12345,
      #     "isdir": 0,
      #     "request_id": 12314124
      #   }
      #   :path  秒传文件的绝对路径
      #   :size  秒传文件的字节大小
      #   :ctime 秒传文件的创建时间。
      #   :mtime 秒传文件的修改时间
      #   :md5   秒传文件的md5签名
      #   :fs_id 秒传文件在PCS的唯一标识ID
      #   :isdir  “0”文件 “1”目录
      #
      # @param path           [String] 上传文件的全路径名（相对于应用根目录）
      # @param content_length [Fixnum] 待秒传的文件长度
      # @param content_md5    [String] 待秒传的文件的MD5
      # @param slice_md5      [String] 待秒传文件校验段的MD5
      # @param content_crc32  [String] 待秒传文件校验段的MD5
      # @param overwrite      [Boolean] +true+: 表示覆盖同名文件，+false+：表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E7.A7.92.E4.BC.A0.E6.96.87.E4.BB.B6a 秒传文件
      def rapid_upload(path, content_length, content_md5, slice_md5, content_crc32, overwrite=false)
        path = build_path path, true
        query = { :path             => path,
                  :'content-length' => content_length,
                  :'content-md5'    => content_md5,
                  :'slice-md5'      => slice_md5,
                  :'content-crc32'  => content_crc32 }
        query[:ondup] = overwrite ? 'overwrite' : 'newcopy'
        post "#{BASE_PATH}/file", query.update(base_query 'rapidupload')
      end

      # 添加离线下载任务，实现单个文件离线下载
      #
      # @example 返回的原始 JSON
      #   {"task_id":432432432432432,"request_id":3372220525}
      #
      #   :task_id 任务ID号
      #
      # @param source_url [String] 源文件的URL
      # @option options :save_path  [String] 下载后的文件保存路径（相对于应用根目录）
      #                                      如果未指定则获取源文件的URL名称，如果获取失败则使用当前时间
      # @option options :timeout    [Fixnum] 下载超时时间
      # @option options :expires    [Fixnum] 请求失效时间，如果有，则会校验
      # @option options :rate_limit [Fixnum] 下载限速，默认不限速
      # @option options :callback   [String] 下载完毕后的回调
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.B7.BB.E5.8A.A0.E7.A6.BB.E7.BA.BF.E4.B8.8B.E8.BD.BD.E4.BB.BB.E5.8A.A1 添加离线下载任务
      def add_task(source_url, options={})
        query = { source_url: source_url }
        query[:timeout] = options.delete(:timeout) || 3600
        save_path = options.delete(:save_path)
        unless save_path
          save_path = URI(source_url).path.split('/').last || Time.now.localtime.to_s
        end
        save_path = build_path save_path, true
        query[:save_path] = save_path
        query.update options
        post "#{BASE_PATH}/services/cloud_dl", query.update(base_query 'add_task')
      end

      # 精确查询离线下载任务
      #
      # 根据任务ID号，查询离线下载任务信息及进度信息
      #
      # @example 查询进度信息，返回的原始 JSON
      #   {
      #     "task_info": {
      #       "23998044": {
      #         "create_time": "1384703711",
      #         "start_time": "1384703711",
      #         "finish_time": "1384703717",
      #         "file_size": "0",
      #         "finished_size": "0",
      #         "task_name": "1.dmg",
      #         "save_path": "/apps/album/1.dmg",
      #         "source_url": "https://example.com/1.dmg",
      #         "status": "1",
      #         "result": 0
      #       }
      #     },
      #     "request_id": 631260401
      #   }
      #
      #   :result 0查询成功，结果有效，1要查询的task_id不存在
      #   :status 0下载成功，1下载进行中 2系统错误，3资源不存在，4下载超时，
      #           5资源存在但下载失败 6存储空间不足 7任务取消
      #   :status status为0、1时，其余字段有效
      #
      # @example 查询任务信息，返回的原始 JSON
      #   {
      #     "task_info": {
      #       "23654044": {
      #         "source_url": "https://example.com/1.dmg",
      #         "finished_size": "0",
      #         "save_path": "/apps/album/1.dmg",
      #         "rate_limit": "0",
      #         "timeout": "3600",
      #         "callback": "",
      #         "status": "7",
      #         "create_time": "1384703711",
      #         "task_name": "1.dmg",
      #         "od_type": "0",
      #         "result": 0
      #       }
      #     },
      #     "request_id": 689959608
      #   }
      #
      #   :result      0查询成功，结果有效，1要查询的task_id不存在
      #   :source_url  下载数据源地址
      #   :save_path   下载完成后的存放地址
      #   :status      0下载成功，1下载进行中 2系统错误，3资源不存在，4下载超时，
      #                5资源存在但下载失败 6存储空间不足 7目标地址数据已存在 8任务取消
      #   :create_time 任务创建时间
      #
      # @overload query_task(task_id, options={})
      #   @param task_id [String] 要查询的任务ID
      #   @return [Hash]
      #
      # @overload query_task(task_ids, options={})
      #   @param task_ids [Array<String>] 要查询的任务ID
      #   @return [Hash]
      #
      # @option options [Fixnum] :op_type 0：查任务信息；1：查进度信息；默认为1
      # @option options [Fixnum] :expires 请求失效时间，如果有，则会校验
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E7.B2.BE.E7.A1.AE.E6.9F.A5.E8.AF.A2.E7.A6.BB.E7.BA.BF.E4.B8.8B.E8.BD.BD.E4.BB.BB.E5.8A.A1 精确查询离线下载任务
      def query_task(task_ids, options={})
        task_ids = task_ids.join(',') if task_ids.is_a? Array
        query = { task_ids: task_ids }.update options
        post "#{BASE_PATH}/services/cloud_dl", query.update(base_query 'query_task')
      end

      # 查询离线下载任务列表
      #
      # 查询离线下载任务ID列表及任务信息
      #
      # @example 不包含任务信息，返回的原始 JSON
      #   {"task_info":[{"task_id":"26"}, {"task_id":"27"}],"total":"2","request_id":1283164486}
      #
      # @example 包含任务信息，返回的原始 JSON
      #   {
      #     "task_info": [
      #       {
      #         "task_id": "26",
      #         "source_url": "https://example.com/1.dmg",
      #         "save_path": "/apps/album/1.dmg",
      #         "rate_limit": "100",
      #         "timeout": "10000",
      #         "callback": "",
      #         "status": "1",
      #         "create_time": "1347449048"
      #       }
      #     ],
      #     "total": "1",
      #     "request_id": 1285732167
      #   }
      #
      # @param [Hash] options 皆为可选参数
      # @option options [Fixnum] :start          查询任务起始位置，默认为0
      # @option options [Fixnum] :limit          设定返回任务数量，默认为10
      # @option options [Fixnum] :asc            0：降序；1：升序；默认为0
      # @option options [Fixnum] :need_task_info 是否需要返回任务信息：0：不需要；1：需要；默认为1
      # @option options [Fixnum] :status         任务状态
      # @option options [Fixnum] :create_time    任务创建时间，note：此参数似乎无效
      # @option options [String] :source_url     源地址URL
      # @option options [String] :save_path      文件保存路径（相对于应用根目录）
      # @option options [Fixnum] :expires        请求失效时间，如果有，则会校验
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.9F.A5.E8.AF.A2.E7.A6.BB.E7.BA.BF.E4.B8.8B.E8.BD.BD.E4.BB.BB.E5.8A.A1.E5.88.97.E8.A1.A8 查询离线下载任务列表
      def list_task(options={})
        query = options.dup
        post "#{BASE_PATH}/services/cloud_dl", query.update(base_query 'list_task')
      end

      # 取消离线下载任务
      #
      # @example 返回的原始 JSON
      #   {"request_id":12394838223}
      #
      # @param task_id [String] 要取消的任务ID号
      # @param expires [Fixnum] 请求失效时间，如果有，则会校验
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E5.8F.96.E6.B6.88.E7.A6.BB.E7.BA.BF.E4.B8.8B.E8.BD.BD.E4.BB.BB.E5.8A.A1 取消离线下载任务
      def cancel_task(task_id, expires=nil)
        query = { task_id: task_id, expires: expires }
        post "#{BASE_PATH}/services/cloud_dl", query.update(base_query 'cancel_task')
      end

      # @!endgroup

      # @!group 3 回收站

      # 查询回收站文件
      #
      # 获取回收站中的文件及目录列表
      #
      # @example 返回的原始 JSON
      #   {
      #     "list": [
      #       {
      #         "fs_id": 1579174,
      #         "path": "/apps/album/2.7z",
      #         "ctime": 1361934614,
      #         "mtime": 1361934625,
      #         "md5": "1131170ac11cfbec411a5e8d4e111769",
      #         "size": 10730431,
      #         "isdir": 0
      #       },
      #       {
      #         "fs_id": 304521061,
      #         "path": "/apps/album/3.7z",
      #         "ctime": 1361934605,
      #         "mtime": 1361934625,
      #         "md5": "9552bf5e5abdf962e2de94be243bec7c",
      #         "size": 4287611,
      #         "isdir": 0
      #       }
      #     ],
      #     "request_id": 3779302504
      #   }
      #
      #   :fs_id 目录在PCS上的临时唯一标识
      #   :path  该目录的绝对路径
      #   :ctime 文件在服务器上的创建时间
      #   :mtime 文件在服务器上的修改时间
      #   :md5   分片MD5
      #   :size  文件大小（byte）
      #   :isdir 是否是目录的标识符：
      #
      # @param start [Fixnum] 返回条目的起始值
      # @param limit [Fixnum] 返回条目的长度
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.9F.A5.E8.AF.A2.E5.9B.9E.E6.94.B6.E7.AB.99.E6.96.87.E4.BB.B6 查询回收站文件
      def listrecycle(start=0, limit=1000)
        query = { start:start, limit: limit }
        get "#{BASE_PATH}/file", query.update(base_query 'listrecycle')
      end

      # 单个或批量还原文件/目录
      # @note 非强一致接口，调用后请sleep 1秒读取
      # @overload restore(fs_id)
      #   还原单个文件或目录
      #
      #   @example 还原成功返回的原始 JSON
      #     {"extra":{"list":[{"fs_id":"1356099017"}]},"request_id":3775323016}
      #
      #   @param [String] fs_id 所还原的文件或目录在PCS的临时唯一标识ID
      #   @return [Hash]
      #
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E8.BF.98.E5.8E.9F.E5.8D.95.E4.B8.AA.E6.96.87.E4.BB.B6.E6.88.96.E7.9B.AE.E5.BD.95 还原单个文件或目录
      #
      # @overload restore(fs_ids)
      #   批量还原文件或目录
      #
      #   @example 全部还原成功返回的原始 JSON
      #     {"extra":{"list":[{"fs_id":"3275514389"}]},"request_id":3859098573}
      #   @example 部分还原成功返回的原始 JSON
      #     {"error_code":31078,"error_msg":"invalid fs id","extra":{"list":[{"fs_id":"706533300"}]},"request_id":3825218191}
      #   @example 全部还原失败返回的原始 JSON
      #     {"error_code":31078,"error_msg":"invalid fs id","extra":{"list":[]},"request_id":805400333}
      #
      #   @param [Array<String>] fs_ids 所还原的文件或目录在PCS的临时唯一标识ID的数组
      #   @return [Hash]
      #   @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.89.B9.E9.87.8F.E8.BF.98.E5.8E.9F.E6.96.87.E4.BB.B6.E6.88.96.E7.9B.AE.E5.BD.95 批量还原文件或目录
      #
      # @return [Hash]
      def restore(fs_ids)
        query = case fs_ids
                when String
                  { fs_id: fs_ids }
                when Array
                  fs_ids = fs_ids.map { |id| { fs_id: id } }
                  { param: JSON.dump({ list: fs_ids }) }
                else
                  raise ArgumentError, 'fs_id(s) must be kind of String or Array'
                end
        post "#{BASE_PATH}/file", query.update(base_query 'restore')
      end

      # 清空回收站
      #
      # @example 返回的原始 JSON
      #   {"request_id":2307473052}
      #
      # @return [Hash]
      # @see http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list#.E6.B8.85.E7.A9.BA.E5.9B.9E.E6.94.B6.E7.AB.99 清空回收站
      def empty
        query = { type: 'recycle' }
        post "#{BASE_PATH}/file", query.update(base_query 'delete')
      end

      # @!endgroup

      private

      def base_query(method)
        { method: method, access_token: @access_token }
      end

      # 构建上传 query hash
      # 如果 +path+ 中包含 +"\\ ? | " > < : *"+, 则被替换为 +"_"+
      # 如果 +path+ 开头结尾包含 +"."+ 或 空白符, 则将被删除
      #
      # [method]    api 中 method 的固定值
      # [path]      上传文件路径(含上传的文件名称)
      # [overwrite] +true+:  表示覆盖同名文件
      #             +false+: 表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”
      # [tmpfile]   +true+:  表示使用分块上传，此时将忽略上述四个参数
      #             +false+: 表示正常上传，不使用分块上传
      def build_upload_query(method, path, overwrite=false, tmpfile=false)
        if tmpfile
          query = { type: 'tmpfile' }
        else
          path = build_path path, true
          ondup = overwrite ? 'overwrite' : 'newcopy'
          query = { path: path, ondup: ondup }
        end

        #文档提醒：file需通过POST表单进行传递，其他参数则需通过query_string进行传递。
        query.update base_query(method)
      end

      def build_path(path, edit=false)
        if Util.blank? path
          raise ArgumentError, 'path must not be blank'
        end
        if path.bytesize > 1000
          raise ArgumentError, 'path length must not be greater than 1000'
        end
        path = Util.edit_path path if edit  # edit path to meet api rule
        File.join @dir_path, path           # add app path
      end

      def with_retries(max_retry_times, waitsec)
        retry_times = 0
        begin
          yield
        rescue => e
          raise if (retry_times += 1) > max_retry_times
          warn "#{self.class.name} error occured: #{e.inspect}, will retry in #{waitsec} seconds for the #{retry_times}th time."
          sleep waitsec
          retry
        end
      end

      def move_or_copy(method, from, to)
        body = case from
               when String
                 raise ArgumentError, 'from and to must have the same type' unless to.is_a? String
                 from = build_path from
                 to   = build_path to, true
                 { from: from, to: to }
               when Array
                 raise ArgumentError, 'from and to must have the same type' unless to.is_a? Array
                 raise ArgumentError, 'from or to must not be empty'        if from.empty? || to.empty?
                 raise ArgumentError, 'from and to must have the same size' unless from.size == to.size
                 list = []
                 from.zip(to) { |arr| list << { from: build_path(arr[0]), to: build_path(arr[1], true) } }
                 { param: JSON.dump({ list: list }) }
               else
                 raise ArgumentError, 'from and to must be kind of String or Array'
               end
        post "#{BASE_PATH}/file", base_query(method.to_s), body
      end

      def meta_or_delete(method, path)
        query = case path
                when String
                  path = build_path path
                  { path: path }
                when Array
                  raise ArgumentError, 'path(s) must not be empty' if path.empty?
                  paths = path.map { |p| { path: build_path(p) } }
                  { param: JSON.dump({ list: paths }) }
                else
                  raise ArgumentError, 'path must be kind of String or Array'
                end
        get "#{BASE_PATH}/file", query.update(base_query method.to_s)
      end
    end
  end
end
