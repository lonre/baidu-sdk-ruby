# encoding: UTF-8

require 'spec_helper'
require 'baidu/pcs'

describe Baidu::PCS do
  let(:target_file) { ft('logo.png') }

  before :all do
    Baidu.config do |c|
      c.pcs_dir_name = 'Backups'
    end
    @client = Baidu::PCS::Client.new('ATOKEN')
  end

  describe '.initialize' do
    it 'assgins access token and default site' do
      expect(Baidu::PCS::SITE).to          eq('https://pcs.baidu.com')
      expect(Baidu::PCS::UPLOAD_SITE).to   eq('https://c.pcs.baidu.com')
      expect(Baidu::PCS::DOWNLOAD_SITE).to eq('https://d.pcs.baidu.com')
      expect(Baidu::PCS::BASE_PATH).to     eq('/rest/2.0/pcs')
      expect(@client.instance_variable_get('@site')).to         eq('https://pcs.baidu.com')
      expect(@client.instance_variable_get('@access_token')).to eq('ATOKEN')
    end

    it 'assgins access token with session' do
      session = Baidu::Session.new
      session.access_token = 'ATOKEN_SESSION'
      client = Baidu::PCS::Client.new(session)
      expect(client.instance_variable_get(:@access_token)).to eq('ATOKEN_SESSION')
    end

    it 'raises argument error' do
      expect { Baidu::PCS::Client.new(nil) }.to raise_error(ArgumentError, 'access_token must not be blank')
      expect {
        Baidu::PCS::Client.new('ATOKEN', nil)
      }.to raise_error(ArgumentError, 'dir_name must not be blank')
    end

    it 'uses app name from method param' do
      Baidu.pcs_dir_name = 'Backups'
      c = Baidu::PCS::Client.new('ATOKEN', 'Backups2')
      expect(c.instance_variable_get(:@dir_name)).to eq('Backups2')
    end
  end

  describe '#quota' do
    before do
      stub_get(:pcs, '/quota', method: 'info', access_token: 'ATOKEN').to_return(status: 200, body: ft('quota.json'))
    end

    it 'requests quota api' do
      @client.quota
      a_get(:pcs, '/quota', method: 'info', access_token: 'ATOKEN').should have_been_made
    end

    it 'responses quota info' do
      result = @client.quota
      expect(result).to be_instance_of(Hash)
      expect(result).to have_key(:quota)
      expect(result).to have_key(:used)
    end
  end

  describe '#upload' do
    describe 'single file' do
      let(:file) { ft('logo.png') }
      let(:url)  { /pcs.baidu.com\/rest\/2.0\/pcs\// }
      let(:uploadquery) { { method: 'upload', access_token: 'ATOKEN', ondup: 'newcopy' } }

      before do
        IO.stub(:binread).and_return('')
        stub_request(:post, url)
      end

      it 'validates method parmas' do
        expect { @client.upload('/tmp/file.txt') }.to raise_error(ArgumentError, 'file must be an instance of File')
      end

      context 'without block_upload' do
        it 'uploads 256MB file' do
          file.stub(:size).and_return 256*1024*1024
          @client.upload file, block_upload: false
          a_request(:post, url).should have_been_made.times(1)
          a_request(:post, url).with(query: hash_including({ method: 'upload' })).should have_been_made.times(1)
          a_request(:post, url).with(query: hash_including({ type: 'tmpfile' })).should have_been_made.times(0)
          a_request(:post, url).with(query: hash_including({ method: 'createsuperfile' })).should have_been_made.times(0)
        end

        it 'uploads 2GB file' do
          file.stub(:size).and_return 2*1024*1024*1024
          expect { @client.upload(file, block_upload: false) }.not_to raise_error
        end

        it 'uploads 2.1GB file' do
          file.stub(:size).and_return 2.1*1024*1024*1024
          expect { @client.upload(file, block_upload: false) }.to raise_error(IOError, 'file is too large (larger than 2G)')
        end
      end

      context 'with block_upload' do
        it 'uploads 7MB file' do
          file.stub(:size).and_return 7*1024*1024
          @client.upload file, block_upload: true
          a_request(:post, url).should have_been_made.times(1)
          a_request(:post, url).with(query: hash_including({ method: 'upload' })).should have_been_made.times(1)
          a_request(:post, url).with(query: hash_including({ type: 'tmpfile' })).should_not have_been_made
          a_request(:post, url).with(query: hash_including({ method: 'createsuperfile' })).should_not have_been_made
        end

        it 'uploads 8MB file' do
          file.stub(:size).and_return 8*1024*1024
          @client.upload file, block_upload: true
          a_request(:post, url).should have_been_made.times(3)
          a_request(:post, url).with(query: hash_including({ method: 'upload' })).should have_been_made.times(2)
          a_request(:post, url).with(query: hash_including({ type: 'tmpfile' })).should have_been_made.times(2)
          a_request(:post, url).with(query: hash_including({ method: 'createsuperfile' })).should have_been_made.times(1)
        end

        it 'uploads 22MB file' do
          file.stub(:size).and_return 22*1024*1024
          @client.upload file, block_upload: true
          a_request(:post, url).should have_been_made.times(7)
          a_request(:post, url).with(query: hash_including({ method: 'upload' })).should have_been_made.times(6)
          a_request(:post, url).with(query: hash_including({ type: 'tmpfile' })).should have_been_made.times(6)
          a_request(:post, url).with(query: hash_including({ method: 'createsuperfile' })).should have_been_made.times(1)
        end

        it 'is waiting for retry'
        # it 'is waiting for retry' do
        #   allow(Kernel).to  receive(:sleep)
        #   allow(file).to    receive(:size).and_return(256*1024*1024)
        #   allow(@client).to receive(:upload_block).and_raise(ArgumentError)
        #   begin
        #     @client.upload file, retry_waitsec: 1, retry_times: 2
        #   rescue
        #   end
        #   expect(@client).to receive(:upload_block).exactly(2).times
        #   # expect(Kernel).to receive(:sleep).exactly(2).times
        # end
      end

      it 'sets right request header' do
        query = URI.encode_www_form( { path: '/apps/Backups/api测试/图片/标识.png' }.merge uploadquery )
        stub_post(:pcs_upload, '/file?' + query).to_return(status: 200, body: ft('upload.json'))

        @client.upload(target_file, path: 'api测试/图片/标识.png')
        a_post(:pcs_upload, '/file?' + query).should have_been_made
      end

      it 'overwrite existing file' do
        uploadquery[:ondup] = 'overwrite'
        query = URI.encode_www_form( { path: '/apps/Backups/a/apitest.png' }.merge uploadquery )
        stub_post(:pcs_upload, '/file?' + query).to_return(status: 200, body: ft('upload.json'))

        @client.upload(target_file, path: 'a/apitest.png', overwrite: true)
        a_post(:pcs_upload, '/file?' + query).should have_been_made
      end

      it 'raise exception when path length is too long' do
        expect {
          @client.upload(target_file, path: 'a'*1001)  # name bytesize > 1000
        }.to raise_error(ArgumentError, 'path length must not be greater than 1000')

        query = URI.encode_www_form( { path: ('/apps/Backups/' + 'a'*1000) }.merge uploadquery )
        stub_post(:pcs_upload, '/file?' + query)
        expect { @client.upload(target_file, path: 'a'*1000) }.not_to raise_error
      end
    end
  end

  describe '#upload_block' do
    let(:query) {
      URI.encode_www_form({
        method: 'upload',
        access_token: 'ATOKEN',
        type: 'tmpfile'
      })
    }

    it 'sets blocked upload params type tmpfile' do
      stub_post(:pcs_upload, '/file?' + query).to_return(status: 200, body: ft('upload_block.json'))
      @client.upload_block(IO.read target_file, 10)
      a_post(:pcs_upload, '/file?' + query).should have_been_made
    end

  end

  describe '#create_super_file' do
    let(:uploadquery) { {
      method: 'createsuperfile',
      access_token: 'ATOKEN',
      ondup: 'newcopy'
    } }

    let(:block_list) { %w[abc def ghi] }

    it 'overwrite existing file' do
      uploadquery[:ondup] = 'overwrite'
      query = URI.encode_www_form( { path: '/apps/Backups/a/apitest.png' }.merge uploadquery )
      param = JSON.dump({ block_list: block_list })
      stub_post(:pcs, '/file?' + query, param: param).to_return(status: 200, body: ft('upload.json'))

      @client.create_super_file(block_list, 'a/apitest.png', true)
      a_post(:pcs, '/file?' + query, param: param).should have_been_made
    end

    it 'finish blocked file upload' do
      query = URI.encode_www_form({ path: ('/apps/Backups/upload_block/标识.png') }.merge uploadquery)
      param = JSON.dump({ block_list: block_list })
      stub_post(:pcs, '/file?' + query, param: param).to_return(status: 200, body: ft('upload.json'))
      @client.create_super_file(block_list, 'upload_block/标识.png')
      a_post(:pcs, '/file?' + query, param: param).should have_been_made
    end

    it 'raise exception when path length is too long' do
      expect {
        @client.create_super_file(block_list, 'a'*1001)  # name bytesize > 1000
      }.to raise_error(ArgumentError, 'path length must not be greater than 1000')

      query = URI.encode_www_form({ path: ('/apps/Backups/' + 'a'*1000) }.merge uploadquery)
      stub_post(:pcs, '/file?' + query)
      expect { @client.create_super_file(block_list, 'a'*1000) }.not_to raise_error
    end

    it 'raise exception when path is blank' do
      expect { @client.create_super_file(block_list, ' ') }.to raise_error(ArgumentError, 'path must not be blank')
      expect { @client.create_super_file(block_list, nil) }.to raise_error(ArgumentError, 'path must not be blank')
    end
  end

  describe '#download' do
    let(:qparams) { { method: 'download', access_token: 'ATOKEN', path: '/apps/Backups/api测试/图片/标识.png'} }
    let(:query) { URI.encode_www_form(qparams) }

    it 'download file with raw body' do
      stub_get(:pcs_download, '/file?' + query).to_return(status: 200, body: ft('logo.png'))
      @client.download('api测试/图片/标识.png')
      a_get(:pcs_download, '/file?' + query).should have_been_made
    end

    it 'download specified range(0-4) of file' do
      stub_get(:pcs_download, '/file?' + query)
      @client.download('api测试/图片/标识.png', begin: 0, end: 4)
      a_request(:get, /d.pcs.baidu.com.+\/file\?/).
        with(query: hash_including(qparams), headers: { Range: 'bytes=0-4' }).should have_been_made
    end

    it 'download specified range(0-100) of file' do
      stub_get(:pcs_download, '/file?' + query)
      @client.download('api测试/图片/标识.png', end: 100)
      a_request(:get, /d.pcs.baidu.com.+\/file\?/).
        with(query: hash_including(qparams), headers: { Range: 'bytes=0-100' }).should have_been_made
    end

    it 'download specified range(100-) of file' do
      stub_get(:pcs_download, '/file?' + query)
      @client.download('api测试/图片/标识.png', begin: 100)
      a_request(:get, /d.pcs.baidu.com.+\/file\?/).
        with(query: hash_including(qparams), headers: { Range: 'bytes=100-' }).should have_been_made
    end

    it 'download specified range(100-200) of file' do
      stub_get(:pcs_download, '/file?' + query)
      @client.download('api测试/图片/标识.png', begin: 100, end: 200)
      a_request(:get, /d.pcs.baidu.com.+\/file\?/).
        with(query: hash_including(qparams), headers: { Range: 'bytes=100-200' }).should have_been_made
    end

    it 'download file chunked' do
      stub_get(:pcs_download, '/file?' + query).to_return(status: 200, body: ft('logo.png'))
      content = ''
      @client.download('api测试/图片/标识.png') do |chunk|
        content << chunk
      end
      a_get(:pcs_download, '/file?' + query).should have_been_made
      expect(content).not_to be_empty
    end

    it 'download specified range(100-200) of file chunked' do
      stub_get(:pcs_download, '/file?' + query).to_return(status: 200, body: ft('logo.png'))
      content = ''
      @client.download('api测试/图片/标识.png', begin: 100, end: 200) do |chunk|
        content << chunk
      end
      a_request(:get, /d.pcs.baidu.com.+\/file\?/).
        with(query: hash_including(qparams), headers: { Range: 'bytes=100-200' }).should have_been_made
      expect(content).not_to be_empty
    end
  end

  describe '#mkdir' do
    let(:query) {
      URI.encode_www_form({
        method: 'mkdir',
        access_token: 'ATOKEN',
        path: '/apps/Backups/apitest'
      })
    }

    it 'makes dir' do
      stub_post(:pcs, '/file?' + query).to_return(status: 200, body: ft('mkdir.json'))
      @client.mkdir('apitest')
      a_post(:pcs, '/file?' + query).should have_been_made
    end
  end

  describe '#meta' do
    describe 'when single file or dir' do
      let(:query) {
        URI.encode_www_form({
          method: 'meta',
          access_token: 'ATOKEN',
          path: '/apps/Backups/apitest'
        })
      }

      it 'raise exception when path is blank' do
        expect { @client.meta('') }.to  raise_error(ArgumentError, 'path must not be blank')
        expect { @client.meta(' ') }.to raise_error(ArgumentError, 'path must not be blank')
        expect { @client.meta(nil) }.to raise_error(ArgumentError, 'path must be kind of String or Array')
      end

      it 'gets meta infomation' do
        stub_get(:pcs, '/file?' + query).to_return(status: 200, body: ft('meta.json'))
        @client.meta('apitest')
        a_get(:pcs, '/file?' + query).should have_been_made
      end
    end

    describe 'when multiple files or dirs' do
      let(:query) {
        URI.encode_www_form({
          method: 'meta',
          access_token: 'ATOKEN',
          param: JSON.dump({list: [ { path: '/apps/Backups/a/b' },
                                    { path: '/apps/Backups/c' },
                                    { path: '/apps/Backups/d/e/f' } ]
                          })
        })
      }
      let(:paths) { %w[a/b c d/e/f] }

      it 'raise exception when path is blank' do
        expect { @client.meta([]) }.to         raise_error(ArgumentError, 'path(s) must not be empty')
        expect { @client.meta(nil) }.to        raise_error(ArgumentError, 'path must be kind of String or Array')
        expect { @client.meta(['']) }.to       raise_error(ArgumentError, 'path must not be blank')
        expect { @client.meta(['a'*1001]) }.to raise_error(ArgumentError, 'path length must not be greater than 1000')
      end

      it 'gets meta infomation' do
        stub_get(:pcs, '/file?' + query).to_return(status: 200, body: ft('meta.json'))
        @client.meta(paths)
        a_get(:pcs, '/file?' + query).should have_been_made
      end
    end
  end

  describe '#list' do
    let(:query) {
      URI.encode_www_form({
        method: 'list',
        access_token: 'ATOKEN',
        path: '/apps/Backups/apitest'
      })
    }

    it 'requests with default params' do
      stub = stub_get(:pcs, '/file?' + query + '&by=name&order=desc').to_return(status: 200, body: ft('list.json'))
      @client.list('apitest')
      stub.should have_been_requested
    end

    it 'requests with options' do
      stub = stub_get(:pcs, '/file?' + query + '&order=asc&by=time&limit=2-10').to_return(status: 200, body: ft('list.json'))
      @client.list('apitest', order: 'asc', by: 'time', limit: '2-10')
      stub.should have_been_requested
    end
  end

  describe '#move' do
    describe 'when from and to are both single paths' do
      let(:query) {
        URI.encode_www_form({
          method: 'move',
          access_token: 'ATOKEN'
        })
      }

      it 'moves apitest to apitestnew' do
        stub_post(:pcs, '/file?' + query, { from: '/apps/Backups/apitest', to: '/apps/Backups/apitestnew' })
                .to_return(status: 200, body: ft('move.json'))
        @client.move('apitest', 'apitestnew')
        a_post(:pcs, '/file?' + query, { from: '/apps/Backups/apitest', to: '/apps/Backups/apitestnew' })
              .should have_been_made
      end

      it 'raise exception when from or to is invalid' do
        expect{ @client.move('a', %w[b]) }.to raise_error(ArgumentError, 'from and to must have the same type')
        expect{ @client.move(nil, '') }.to    raise_error(ArgumentError, 'from and to must be kind of String or Array')
        expect{ @client.move('', 'b') }.to    raise_error(ArgumentError, 'path must not be blank')
        expect{ @client.move('a', '') }.to    raise_error(ArgumentError, 'path must not be blank')
      end
    end

    describe 'when from and to are both multiple paths' do
      let(:query) {
        URI.encode_www_form({
          method: 'move',
          access_token: 'ATOKEN',
        })
      }
      let(:param) {
        JSON.dump({ list: [{from: '/apps/Backups/a', to: '/apps/Backups/b'},
                           {from: '/apps/Backups/a/b/c', to: '/apps/Backups/abc'}]
                  })
      }

      it 'moves multiple paths to other paths' do
        stub_post(:pcs, '/file?' + query, { param: param }).to_return(status: 200, body: ft('move.json'))
        @client.move(%w[a a/b/c], %w[b abc])
        a_post(:pcs, '/file?' + query, { param: param })
      end

      it 'raise exception when from or to is invalid' do
        expect{ @client.move([], %w[a]) }.to   raise_error(ArgumentError, 'from or to must not be empty')
        expect{ @client.move(%w[a], []) }.to   raise_error(ArgumentError, 'from or to must not be empty')
        expect{ @client.move(%w[a], ['']) }.to raise_error(ArgumentError, 'path must not be blank')
        expect{ @client.move(nil, ['']) }.to   raise_error(ArgumentError, 'from and to must be kind of String or Array')
        expect{ @client.move([''], nil) }.to   raise_error(ArgumentError, 'from and to must have the same type')
        expect{ @client.move(%w[a], %w[ab cd]) }.to raise_error(ArgumentError, 'from and to must have the same size')
      end
    end
  end

  describe '#copy' do
    describe 'when from and to are both single paths' do
      let(:query) {
        URI.encode_www_form({
          method: 'copy',
          access_token: 'ATOKEN'
        })
      }

      it 'copys apitest to apitestnew' do
        stub_post(:pcs, '/file?' + query, { from: '/apps/Backups/apitest', to: '/apps/Backups/apitestcopy' })
                .to_return(status: 200, body: ft('copy.json'))
        @client.copy('apitest', 'apitestcopy')
        a_post(:pcs, '/file?' + query, { from: '/apps/Backups/apitest', to: '/apps/Backups/apitestcopy' })
              .should have_been_made
      end

      it 'raise exception when from or to is invalid' do
        expect{ @client.copy('a', %w[b]) }.to raise_error(ArgumentError, 'from and to must have the same type')
        expect{ @client.copy(nil, '') }.to    raise_error(ArgumentError, 'from and to must be kind of String or Array')
        expect{ @client.copy('', 'b') }.to    raise_error(ArgumentError, 'path must not be blank')
        expect{ @client.copy('a', '') }.to    raise_error(ArgumentError, 'path must not be blank')
      end
    end

    describe 'when from and to are both multiple paths' do
      let(:query) {
        URI.encode_www_form({
          method: 'copy',
          access_token: 'ATOKEN',
        })
      }
      let(:param) {
        JSON.dump({ list: [{from: '/apps/Backups/a', to: '/apps/Backups/b'},
                           {from: '/apps/Backups/a/b/c', to: '/apps/Backups/abc'}]
                  })
      }

      it 'copys multiple paths to other paths' do
        stub_post(:pcs, '/file?' + query, { param: param }).to_return(status: 200, body: ft('copy.json'))
        @client.copy(%w[a a/b/c], %w[b abc])
        a_post(:pcs, '/file?' + query, { param: param })
      end

      it 'raise exception when from or to is invalid' do
        expect{ @client.copy([], %w[a]) }.to   raise_error(ArgumentError, 'from or to must not be empty')
        expect{ @client.copy(%w[a], []) }.to   raise_error(ArgumentError, 'from or to must not be empty')
        expect{ @client.copy(%w[a], ['']) }.to raise_error(ArgumentError, 'path must not be blank')
        expect{ @client.copy(nil, ['']) }.to   raise_error(ArgumentError, 'from and to must be kind of String or Array')
        expect{ @client.copy([''], nil) }.to   raise_error(ArgumentError, 'from and to must have the same type')
        expect{ @client.copy(%w[a], %w[ab cd]) }.to raise_error(ArgumentError, 'from and to must have the same size')
      end
    end
  end

  describe '#delete' do
    describe 'when single file or dir' do
      let(:query) {
        URI.encode_www_form({
          method: 'delete',
          access_token: 'ATOKEN',
          path: '/apps/Backups/apitest'
        })
      }

      it 'raise exception when path is blank' do
        expect { @client.meta('') }.to  raise_error(ArgumentError, 'path must not be blank')
        expect { @client.meta(' ') }.to raise_error(ArgumentError, 'path must not be blank')
        expect { @client.meta(nil) }.to raise_error(ArgumentError, 'path must be kind of String or Array')
      end

      it 'delete file or dir' do
        stub_get(:pcs, '/file?' + query).to_return(status: 200, body: ft('delete.json'))
        @client.delete('apitest')
        a_get(:pcs, '/file?' + query).should have_been_made
      end
    end

    describe 'when multiple files or dirs' do
      let(:query) {
        URI.encode_www_form({
          method: 'delete',
          access_token: 'ATOKEN',
          param: JSON.dump({list: [ { path: '/apps/Backups/a/b' },
                                    { path: '/apps/Backups/c' },
                                    { path: '/apps/Backups/d/e/f' } ]
                          })
        })
      }
      let(:paths) { %w[a/b c d/e/f] }

      it 'raise exception when path is blank' do
        expect { @client.delete([]) }.to         raise_error(ArgumentError, 'path(s) must not be empty')
        expect { @client.delete(nil) }.to        raise_error(ArgumentError, 'path must be kind of String or Array')
        expect { @client.delete(['']) }.to       raise_error(ArgumentError, 'path must not be blank')
        expect { @client.delete(['a'*1001]) }.to raise_error(ArgumentError, 'path length must not be greater than 1000')
      end

      it 'delete files or dirs' do
        stub_get(:pcs, '/file?' + query).to_return(status: 200, body: ft('delete.json'))
        @client.delete(paths)
        a_get(:pcs, '/file?' + query).should have_been_made
      end
    end
  end

  describe '#search' do
    let(:query) {
      URI.encode_www_form({
        method: 'search',
        access_token: 'ATOKEN',
        path: '/apps/Backups/apitest',
        wd: 'keyword'
      })
    }
    it 'search with default params' do
      stub_get(:pcs, '/file?' + query + '&re=0').to_return(status:200, body: ft('search.json'))
      @client.search('apitest', 'keyword')
      a_get(:pcs, '/file?' + query + '&re=0').should have_been_made
    end

    it 'search recursively' do
      stub_get(:pcs, '/file?' + query + '&re=1').to_return(status:200, body: ft('search.json'))
      @client.search('apitest', 'keyword', true)
      a_get(:pcs, '/file?' + query + '&re=1').should have_been_made
    end

    it 'raise exception when path is blank' do
      expect { @client.search('', 'keyword') }.to raise_error(ArgumentError, 'path must not be blank')
    end
  end

  describe '#thumbnail' do
    let(:query) {
      URI.encode_www_form({
        method: 'generate',
        access_token: 'ATOKEN',
        path: '/apps/Backups/apitest/logo.png',
        width: 120,
        height: 40
      })
    }

    it 'raise error when path is blank' do
      expect { @client.thumbnail('', 100, 200) }.to raise_error(ArgumentError, 'path must not be blank')
    end

    it 'requests with default params' do
      stub = stub_get(:pcs, '/thumbnail?' + query + '&quality=100').to_return(status: 200, body: ft('logo.png'))
      @client.thumbnail('apitest/logo.png', 120, 40)
      stub.should have_been_requested
    end

    it 'processes by block' do
      stub = stub_get(:pcs, '/thumbnail?' + query + '&quality=100').to_return(status: 200, body: ft('logo.png'))
      content = ''
      @client.thumbnail('apitest/logo.png', 120, 40) do |c|
        content << c
      end
      stub.should have_been_requested
      expect(content).not_to be_empty
    end
  end

  describe '#diff' do
    let(:query) {
      URI.encode_www_form({
        method: 'diff',
        access_token: 'ATOKEN'
      })
    }

    it 'requests with default params' do
      stub = stub_get(:pcs, '/file?' + query + '&cursor=null').to_return(status: 200, body: ft('diff.json'))
      @client.diff
      stub.should have_been_requested
    end

    it 'requests with cursor' do
      stub = stub_get(:pcs, '/file?' + query + '&cursor=mynewcursor').to_return(status: 200, body: ft('diff.json'))
      @client.diff('mynewcursor')
      stub.should have_been_requested
    end
  end

  describe '#streaming' do
    let(:query) {
      URI.encode_www_form({
        method: 'streaming',
        access_token: 'ATOKEN',
        path: '/apps/Backups/hi.mp4',
        type: 'M3U8_480_360'
      })
    }

    it 'raise error when path is blank' do
      expect { @client.streaming('', 'M3U8_480_360') }.to raise_error(ArgumentError, 'path must not be blank')
    end

    it 'requests streaming content' do
      stub = stub_get(:pcs, '/file?' + query).to_return(status: 200, body: ft('streaming.m3u8'))
      @client.streaming('hi.mp4', 'M3U8_480_360') do |c|
      end
      stub.should have_been_requested
    end
  end

  describe '#stream_list' do
    let(:query) {
      URI.encode_www_form({
        method: 'list',
        access_token: 'ATOKEN',
        type: 'video'
      })
    }

    it 'requests with default parmas' do
      stub = stub_get(:pcs, '/stream?' + query).to_return(status: 200, body: ft('stream_list.json'))
      @client.stream_list('video')
      stub.should have_been_requested
    end

    it 'requests stream list' do
      stub = stub_get(:pcs, '/stream?' + query + '&start=10&limit=34&filter_path=/apps/Backups').to_return(status: 200, body: ft('stream_list.json'))
      @client.stream_list('video', start: 10, limit: 34, filter_path: '/apps/Backups')
      stub.should have_been_requested
    end
  end

  describe '#rapid_upload' do
    let(:query) {
      URI.encode_www_form({
        method: 'rapidupload',
        access_token: 'ATOKEN',
        path: '/apps/Backups/my_goo_gl.mkv',
        :'content-length' => 74818037,
        :'content-md5'    => 'xxx',
        :'slice-md5'      => 'yyy',
        :'content-crc32'  => 'zzz'
      })
    }

    it 'checks and edit path' do
      stub = stub_post(:pcs, '/file?' + query + '&ondup=newcopy').to_return(status: 200, body: ft('rapidupload.json'))
      expect { @client.rapid_upload('', 1, '2', '3', '4') }.to raise_error(ArgumentError, 'path must not be blank')
      @client.rapid_upload('my|goo>gl.mkv', 74818037, 'xxx', 'yyy', 'zzz')
      stub.should have_been_requested
    end

    it 'requests with default params' do
      stub = stub_post(:pcs, '/file?' + query + '&ondup=newcopy').to_return(status: 200, body: ft('rapidupload.json'))
      @client.rapid_upload('my?goo>gl.mkv', 74818037, 'xxx', 'yyy', 'zzz')
      stub.should have_been_requested
    end
  end

  describe '#add_task' do
    let(:query) {
      URI.encode_www_form({
        method: 'add_task',
        access_token: 'ATOKEN',
        source_url: 'http://test.com/1.png',
        timeout: 3600
      })
    }

    it 'requests with default params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&save_path=/apps/Backups/1.png').to_return(status: 200, body: ft('add_task.json'))
      @client.add_task('http://test.com/1.png', save_path: '1.png')
      stub.should have_been_requested
    end

    it 'requests with params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&save_path=/apps/Backups/2.png&timeout=100&expires=200&rate_limit=300&callback=cb')
                      .to_return(status: 200, body: ft('add_task.json'))
      @client.add_task('http://test.com/1.png', save_path: '2.png', timeout: 100, expires: 200, rate_limit: 300, callback: 'cb')
      stub.should have_been_requested
    end

    it 'set save_path automatically' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&save_path=/apps/Backups/1.png').to_return(status: 200, body: ft('add_task.json'))
      @client.add_task('http://test.com/1.png')
      stub.should have_been_requested
    end

    it 'set save_path automatically' do
      stub_request(:post, /https:\/\/pcs.baidu.com\/rest\/2.0\/pcs\/services\/cloud_dl/)
      @client.add_task('http://test.com/')
      q = 'save_path=/apps/Backups/' + Time.now.localtime.to_s[0..7]
      WebMock.should have_requested(:post, /https:\/\/pcs.baidu.com\/rest\/2.0\/pcs\/services\/cloud_dl/).with { |req| req.uri.query.include? q }
    end
  end

  describe '#query_task' do
    let(:query) {
      URI.encode_www_form({
        method: 'query_task',
        access_token: 'ATOKEN'
      })
    }

    it 'requests with default params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&task_ids=123')
                      .to_return(status: 200, body: ft('query_task_1.json'))
      @client.query_task('123')
      stub.should have_been_requested
    end

    it 'requests with params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&task_ids=456,123&op_type=0&expires=10')
                      .to_return(status: 200, body: ft('query_task_0.json'))
      @client.query_task([456, '123'], op_type: 0, expires: 10)
      stub.should have_been_requested
    end
  end

  describe '#list_task' do
    let(:query) {
      URI.encode_www_form({
        method: 'list_task',
        access_token: 'ATOKEN'
      })
    }

    it 'requests with default params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query)
                      .to_return(status: 200, body: ft('list_task_1.json'))
      @client.list_task
      stub.should have_been_requested
    end

    it 'requests with params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&start=10&limit=20&asc=1&need_task_info=0' \
                              '&status=2&create_time=NULL,1111&source_url=su&save_path=2.png&expires=30')
                      .to_return(status: 200, body: ft('list_task_0.json'))
      @client.list_task(start: 10, limit: 20, asc: 1, need_task_info: 0, status: 2,
                        create_time: 'NULL,1111', source_url: 'su', save_path: '2.png', expires: 30)
      stub.should have_been_requested
    end
  end

  describe '#cancel_task' do
    let(:query) {
      URI.encode_www_form({
        method: 'cancel_task',
        access_token: 'ATOKEN',
        task_id: '48393833'
      })
    }

    it 'requests with default params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query).to_return(status: 200, body: ft('cancel_task.json'))
      @client.cancel_task('48393833')
      stub.should have_been_requested
    end

    it 'requests with params' do
      stub = stub_post(:pcs, '/services/cloud_dl?' + query + '&expires=10').to_return(status: 200, body: ft('cancel_task.json'))
      @client.cancel_task('48393833', 10)
      stub.should have_been_requested
    end
  end

  describe '#listrecycle' do
    let(:query) {
      URI.encode_www_form({
        method: 'listrecycle',
        access_token: 'ATOKEN'
      })
    }

    it 'requests with default params' do
      stub = stub_get(:pcs, '/file?' + query + '&start=0&limit=1000').to_return(status: 200, body: ft('listrecycle.json'))
      @client.listrecycle
      stub.should have_been_requested
    end

    it 'requests with params' do
      stub = stub_get(:pcs, '/file?' + query + '&start=8&limit=30').to_return(status: 200, body: ft('listrecycle.json'))
      @client.listrecycle(8, 30)
      stub.should have_been_requested
    end
  end

  describe '#restore' do
    describe 'when single file or dir' do
      let(:query) {
        URI.encode_www_form({
          method: 'restore',
          access_token: 'ATOKEN',
          fs_id: '8383838383'
        })
      }

      it 'restore with fs_id' do
        stub = stub_post(:pcs, '/file?' + query).to_return(status: 200, body: ft('restore.json'))
        @client.restore('8383838383')
        stub.should have_been_requested
      end
    end

    describe 'when multiple files or dirs' do
      let(:query) {
        URI.encode_www_form({
          method: 'restore',
          access_token: 'ATOKEN',
          param: JSON.dump({list: [ { fs_id: '333333' },
                                    { fs_id: '444444' },
                                    { fs_id: '555555' } ]
                          })
        })
      }
      let(:fs_ids) { %w[333333 444444 555555] }

      it 'restore with fs_id list' do
        stub = stub_post(:pcs, '/file?' + query).to_return(status: 200, body: ft('restore.json'))
        @client.restore(fs_ids)
        stub.should have_been_requested
      end
    end

    it 'restore with invalid fs_id(s)' do
      expect { @client.restore({}) }.to raise_error(ArgumentError, 'fs_id(s) must be kind of String or Array')
      expect { @client.restore(:invalid) }.to raise_error(ArgumentError, 'fs_id(s) must be kind of String or Array')
    end
  end

  describe '#empty' do
    let(:query) {
      URI.encode_www_form({
        method: 'delete',
        access_token: 'ATOKEN',
        type: 'recycle'
      })
    }

    it 'empty recycle' do
      stub = stub_post(:pcs, '/file?' + query).to_return(status: 200, body: ft('empty.json'))
      @client.empty
      stub.should have_been_requested
    end
  end
end
