# Baidu SDK for Ruby [![Build Status](https://travis-ci.org/lonre/baidu-sdk-ruby.png?branch=master)](https://travis-ci.org/lonre/baidu-sdk-ruby)

Unofficial Baidu REST API SDK for Ruby.

非官方百度开放接口 Ruby 开发包。

## 安装

如果你通过 Bundler 来管理你的应用，添加如下一行到应用的 Gemfile 中：

    gem 'baidu-sdk'

然后在终端执行：

    $ bundle

或者直接安装：

    $ gem install baidu-sdk

`baidu-sdk` 当前支持 Ruby(MRI) 版本：1.9.3, 2.0.0

## 使用简介
[baidu-sdk api doc](http://rubydoc.info/gems/baidu-sdk/frames)

本项目根据百度开放接口划分成多个独立模块，如：`Baidu::OAuth`, `Baidu::PCS`等等。

`Hash` 必须使用 `symbol` key，无论是返回值或作为参数传递给方法。

涉及到调用 Baidu REST API 并返回 Hash 时，此 Hash 返回值是在原始 API 返回的 JSON 数据之上 `parse(JSON.parse(resp.body, symbolize_names: true))` 而来。（特别说明返回值的除外，如：`Baidu::OAuth::Flow::Code#get_token` 返回 `Baidu::Session`）。Hash 和 JSON 拥有相同的结构，返回的具体结构可以参考各个方法的 API Doc。如：

```ruby
# 返回的原始 JSON
#   {"quota":15000000000,"used":5221166,"request_id":4043312634}
#
# result 是转换 JSON 后得到的 Hash
#   {:quota=>15000000000, :used=>5221166, :request_id=>4043312634}
result = pcs_client.quota
result[:quota]  # => 15000000000
result[:used]   # => 5221166
```

## OAuth
首先确保已经在百度开发者中心创建了应用。如果还没有创建应用，请通过此链接 [百度开发者中心](http://developer.baidu.com/console) 创建一个新的应用，获取应用的 `API Key` 和 `Secret Key`。

1. 使用全局配置方式：

    ```ruby
    Baidu.config do |c|
      c.client_id     = 'an_api_key'
      c.client_secret = 'a_securet_key'
    end
    ```
    此全局配置为可选方式，还可以在新建 `Baidu::OAuth::Client` 实例的时候指定 `API Key` 和 `Secret Key`。

2. 创建 Baidu::OAuth::Client 实例

    首先，加载 `oauth` 库

    ```ruby
    require 'baidu/oauth'
    ```
    其次，创建实例

    ```ruby
    client = Baidu::OAuth::Client.new
    # 或如下，为实例指定 client_id, client_secret
    client = Baidu::OAuth::Client.new('a_client_id', 'a_client_secret')
    ```
    后者创建的实例受全局配置影响

3. Baidu OAuth 有四种获取 Access Token 的方式，包括 `Authorization Code`, `Implicit Grant`, `Client Credentials`, `Device`以及一个刷新方式`Refresh Token`

    ```ruby
    # 使用 Authorization Code 授权流程，获取 Authorization URL
    client.authorization_code_flow.authorize_url('callback_uri')

    # 使用 Authorization Code 授权流程，获取 Access Token（Baidu::Session）
    client.authorization_code_flow.get_token('code', 'callback_uri')

    # 使用 Device 授权流程，获取 User Code 和 Device Code
    client.device_flow.user_and_device_code

    # 使用 Device 授权流程，获取 Access Token（Baidu::Session）
    client.device_flow.get_token('code')

    # 使用 Implicit Grant 授权流程
    client.implicit_grant_flow.authorize_url('callback_uri')

    # 使用 Implicit Grant 授权流程授权后，
    # 客户端解析 callback_uri 中 Fragment 所携带参数获取 Access Token
    # http://localhost:4567/auth/callback#expires_in=2592000&access_token=3.c79b45...

    # 使用 Client Credentials 授权流程获取 Access Token
    client.client_credentials_flow.get_token

    # 刷新并获取新的 Access Token（Baidu::Session），所有流程均适用
    client.refresh('refresh_token')
    ```

4. `Baidu::Session` 授权信息

    所有 `get_token` 及 `refresh` 均返回 `Baidu::Session`，包含授权信息，如：

    ```ruby
    session = client.device_flow.get_token('code')
    puts session.access_token
    puts session.refresh_token
    puts session.scope
    puts session.session_key
    puts session.session_secret
    ```

### Sinatra Authorization Code 授权简单示例

```ruby
# 1. Edit and save this snippet as code.rb
# 2. Run by: ruby coce.rb
# 3. Visit: http://localhost:4567/auth

require 'sinatra'
require 'baidu/oauth'

Baidu.config do |c|
  c.client_id     = ENV['BAIDU_CLIENT_ID']      # Change to your client_id
  c.client_secret = ENV['BAIDU_CLIENT_SECRET']  # Change to your client_secret
end

# 使用时需要到 http://developer.baidu.com/console 将此 callback 添加到应用安全设置中
callback_uri = 'http://localhost:4567/auth/callback'

get '/' do
  'Hello world!'
end

get '/auth' do
  client = Baidu::OAuth::Client.new
  redirect client.authorization_code_flow.authorize_url(callback_uri, confirm_login: true)
end

get '/auth/callback' do
  begin
    client = Baidu::OAuth::Client.new
    session = client.authorization_code_flow.get_token params[:code], callback_uri
    "auth success: #{session.access_token}"
  rescue => e
    e.to_s
  end
end
```

## PCS
要使用 PCS 必须到 [百度开发者中心](http://developer.baidu.com/console) 开启指定应用的 PCS API 权限，参考 [开通PCS API权限](http://developer.baidu.com/wiki/index.php?title=docs/pcs/guide/api_approve)，并获取所设置的文件目录。

PCS 服务 API 包括文件 API 以及结构化数据 API，目前已经实现全部文件 API。

**API 中涉及到的文件或目录路径，都是相对于开通 PCS API 权限时所设置的文件目录**。比如：上传文件时需要指定文件保存路径，假设指定为 `/mydata/hi.png`，那么在 PCS 中实际的保存路径为 `/apps/文件目录/mydata/hi.png`。

1. 全局配置

    ```ruby
    Baidu.config do |c|
        # ...
        c.pcs_dir_name = 'notes'  # 文件目录名称
        # ...
    end
    ```
    全局配置非强制性的，可以在创建 `Baidu::PCS::Client` 实例时设置

2. 创建 Baidu::PCS::Client 实例

    首先，加载 `pcs` 库

    ```ruby
    require 'baidu/pcs'
    ```
    其次，创建实例

    ```ruby
    client = Baidu::PCS::Client.new('token_or_session')
    # 或如下，为实例指定文件目录
    client = Baidu::PCS::Client.new('token_or_session', 'notes')
    ```

3. API 调用

    ```ruby
    File.open('/opt/ubuntu-12.04.3-server-amd64.iso', 'r') do |f|
        client.upload(f, block_upload: true)
    end
    ```

## 异常处理
API 的异常被封装为 `Baidu::Errors::Error`，包含三个子类：

```
1. Baidu::Errors::AuthError    # 未授权或 Access Token 过期
2. Baidu::Errors::ClientError  # API 返回 400+ 错误
3. Baidu::Errors::ServerError  # API 返回 500+ 错误
```

`Baidu::Errors::Error => e`，异常的具体信息可以通过如下方式获取到：

```ruby
begin
    client.list('apitest/movies')
rescue Baidu::Errors::Error => e
    puts e.code  # 错误代码，详情参考百度开发者中心文档
    puts e.msg   # 错误描述
end
```

## Copyright
MIT License. Copyright (c) 2013 Lonre Wang.
