# encoding: UTF-8

require 'spec_helper'

describe Baidu do
  describe '.from' do
    let(:hash) {
      {
        access_token: "1.a6b7dbd428f731035f771b8d15063f61.86400",
        expires_in: 86400,
        refresh_token: "2.385d55f8615fdfd9edb7c4b5ebdc3e39.604800",
        scope: "basic",
        session_key: "ANXxSNjwQDugf8615OnqeikRMu2bKaXCdlLxn",
        session_secret: "248APxvxjCZ0VEC43EYrvxqaK4oZExMB"
      }
    }

    it 'creates new session from hash' do
      session = Baidu::Session.from hash
      expect(session.access_token).to   eq('1.a6b7dbd428f731035f771b8d15063f61.86400')
      expect(session.refresh_token).to  eq('2.385d55f8615fdfd9edb7c4b5ebdc3e39.604800')
      expect(session.scope).to          eq('basic')
      expect(session.session_key).to    eq('ANXxSNjwQDugf8615OnqeikRMu2bKaXCdlLxn')
      expect(session.session_secret).to eq('248APxvxjCZ0VEC43EYrvxqaK4oZExMB')
    end
  end
end
