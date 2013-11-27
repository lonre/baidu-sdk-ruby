# encoding: UTF-8

require 'spec_helper'

describe Baidu do
  describe '.config' do
    before do
      Baidu.config {}
    end

    it 'has default debug config' do
      expect(Baidu.debug).to be_false
    end

    it 'sets debug config to true' do
      Baidu.config { |c| c.debug = true }
      expect(Baidu.debug).to be_true
    end
  end
end
