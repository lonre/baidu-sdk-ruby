# encoding: UTF-8

require 'json'
require 'net/https'
require 'uri'
require 'baidu/version'
require 'baidu/session'
require 'baidu/errors/error'
require 'baidu/support/util'
require 'baidu/support/request'
require 'baidu/configure'

module Baidu

  class << self
    include Baidu::Configure
  end

end
