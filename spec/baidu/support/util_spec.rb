# encoding: UTF-8

require 'spec_helper'

describe Baidu::Support::Util do
  describe '.blank?' do
    it 'checks non blank value' do
      expect(Baidu::Support::Util.blank? 'abc').to         be false
      expect(Baidu::Support::Util.blank? '  abc ').to      be false
      expect(Baidu::Support::Util.blank? '  你好 ').to     be false
      expect(Baidu::Support::Util.blank? '  你好 ').to     be false
      expect(Baidu::Support::Util.blank? %w[abc]).to       be false
      expect(Baidu::Support::Util.blank?({abc: 'def'})).to be false
      expect(Baidu::Support::Util.blank? true).to          be false
    end

    it 'checks blank value' do
      expect(Baidu::Support::Util.blank? '').to    be true
      expect(Baidu::Support::Util.blank?('  ')).to be true
      expect(Baidu::Support::Util.blank? "\n").to  be true
      expect(Baidu::Support::Util.blank? "\t").to  be true
      expect(Baidu::Support::Util.blank? nil).to   be true
      expect(Baidu::Support::Util.blank? []).to    be true
      expect(Baidu::Support::Util.blank?({})).to   be true
      expect(Baidu::Support::Util.blank? false).to be true
    end
  end

  describe '.edit_path' do
    it 'removes redundant slashes' do
      expect(Baidu::Support::Util.edit_path('/2013//hel///lo.png')).to   eq('/2013/hel/lo.png')
    end

    it 'replace \\\\ ? | " > < : * with _' do
      expect(Baidu::Support::Util.edit_path('2013\\hello?.png')).to  eq('2013_hello_.png')
      expect(Baidu::Support::Util.edit_path('2013|hello*.png')).to   eq('2013_hello_.png')
      expect(Baidu::Support::Util.edit_path('2013"hello:.png')).to   eq('2013_hello_.png')
      expect(Baidu::Support::Util.edit_path('2013>hello<.png')).to   eq('2013_hello_.png')
      expect(Baidu::Support::Util.edit_path('20\\\\\\\\13?|"><:*hello.png')).to eq('20____13_______hello.png')
    end

    it 'removes dot and whitespaces' do
      expect(Baidu::Support::Util.edit_path(' 2013|hello.png..')).to   eq('2013_hello.png')
      expect(Baidu::Support::Util.edit_path('.2013|hello.png  ')).to   eq('2013_hello.png')
      expect(Baidu::Support::Util.edit_path("\n .2013|hello.png . \t")).to eq('2013_hello.png')
    end
  end
end
