require 'rails_helper'

RSpec.describe Admin::ServerMonitorService do
  let(:service) { described_class.new }

  before do
    # Redis関連のモック
    allow(Redis).to receive(:new).and_return(redis_double)

    # Settings関連のモック
    if defined?(Settings)
      allow(Settings).to receive_message_chain(:shlink, :base_url).and_return('https://test.example.com')
      allow(Settings).to receive_message_chain(:shlink, :api_key).and_return('test-api-key')
      allow(Settings).to receive_message_chain(:redis, :url).and_return('redis://test:6379/0')
    end

    # ApplicationConfig関連のモック
    allow(ApplicationConfig).to receive(:string).with('redis.url', anything).and_return('redis://test:6379/0')
  end

  let(:redis_double) do
    instance_double(Redis,
      ping: 'PONG',
      info: {
        'used_memory' => '1048576',
        'used_memory_peak' => '2097152',
        'mem_fragmentation_ratio' => '1.5'
      },
      close: nil
    )
  end

  describe '#call' do
    it '全システム情報を正常に取得すること' do
      result = service.call

      expect(result).to have_key(:system)
      expect(result).to have_key(:performance)
      expect(result).to have_key(:health)
    end

    it 'system情報に必要なキーが含まれること' do
      result = service.call

      expect(result[:system]).to have_key(:memory)
      expect(result[:system]).to have_key(:disk)
      expect(result[:system]).to have_key(:cpu)
      expect(result[:system]).to have_key(:load_average)
    end

    it 'performance情報に必要なキーが含まれること' do
      result = service.call

      expect(result[:performance]).to have_key(:response_time)
      expect(result[:performance]).to have_key(:active_connections)
      expect(result[:performance]).to have_key(:requests_per_minute)
    end

    it 'health情報に必要なキーが含まれること' do
      result = service.call

      expect(result[:health]).to have_key(:database)
      expect(result[:health]).to have_key(:redis)
      expect(result[:health]).to have_key(:external_apis)
      expect(result[:health]).to have_key(:background_jobs)
    end
  end

  describe '#memory_usage (private method)' do
    context '/proc/meminfoが存在する場合' do
      let(:meminfo_content) do
        <<~MEMINFO
          MemTotal:       8388608 kB
          MemAvailable:   5242880 kB
          MemFree:        1048576 kB
        MEMINFO
      end

      before do
        allow(File).to receive(:exist?).with("/proc/meminfo").and_return(true)
        allow(File).to receive(:read).with("/proc/meminfo").and_return(meminfo_content)
      end

      it 'メモリ使用情報を正常に取得すること' do
        result = service.send(:memory_usage)

        expect(result[:total]).to include('GB')
        expect(result[:used]).to include('GB')
        expect(result[:available]).to include('GB')
        expect(result[:usage_percent]).to be_a(Float)
        expect(result[:status]).to be_in(%w[good warning critical])
      end

      it '使用率を正しく計算すること' do
        result = service.send(:memory_usage)
        expected_usage = ((8388608 - 5242880).to_f / 8388608 * 100).round(1)

        expect(result[:usage_percent]).to eq(expected_usage)
      end
    end

    context '/proc/meminfoが存在しない場合' do
      before do
        allow(File).to receive(:exist?).with("/proc/meminfo").and_return(false)
      end

      it 'エラーメッセージを返すこと' do
        result = service.send(:memory_usage)

        expect(result[:error]).to eq("メモリ情報取得不可")
      end
    end
  end

  describe '#disk_usage (private method)' do
    context 'dfコマンドが利用可能な場合' do
      before do
        allow(service).to receive(:system_command_available?).with("df").and_return(true)
        allow(service).to receive(:`).with("df -h / | tail -1").and_return("  /dev/sda1       20G   12G  7.2G  63%   /\n")
      end

      it 'ディスク使用情報を正常に取得すること' do
        result = service.send(:disk_usage)

        expect(result[:total]).to eq('20G')
        expect(result[:used]).to eq('12G')
        expect(result[:available]).to eq('7.2G')
        expect(result[:usage_percent]).to eq(63)
        expect(result[:status]).to be_in(%w[good warning critical])
      end
    end

    context 'dfコマンドが利用できない場合' do
      before do
        allow(service).to receive(:system_command_available?).with("df").and_return(false)
      end

      it 'エラーメッセージを返すこと' do
        result = service.send(:disk_usage)

        expect(result[:error]).to eq("ディスク情報取得不可")
      end
    end
  end

  describe '#cpu_usage (private method)' do
    context '/proc/loadavgが存在する場合' do
      before do
        allow(File).to receive(:exist?).with("/proc/loadavg").and_return(true)
        allow(File).to receive(:read).with("/proc/loadavg").and_return("1.5 2.0 2.5 2/100 12345\n")
        allow(service).to receive(:cpu_core_count).and_return(4)
      end

      it 'CPU使用情報を正常に取得すること' do
        result = service.send(:cpu_usage)

        expect(result[:load_1min]).to eq(1.5)
        expect(result[:load_5min]).to eq(2.0)
        expect(result[:load_15min]).to eq(2.5)
        expect(result[:cores]).to eq(4)
        expect(result[:usage_percent]).to eq(37.5)
        expect(result[:status]).to be_in(%w[good warning critical])
      end
    end

    context '/proc/loadavgが存在しない場合' do
      before do
        allow(File).to receive(:exist?).with("/proc/loadavg").and_return(false)
      end

      it 'エラーメッセージを返すこと' do
        result = service.send(:cpu_usage)

        expect(result[:error]).to eq("CPU情報取得不可")
      end
    end
  end

  describe '#database_health (private method)' do
    it 'データベースヘルス情報を取得すること' do
      allow(service).to receive(:database_connected?).and_return(true)
      allow(service).to receive(:database_response_time).and_return(15.5)
      allow(service).to receive(:database_connections).and_return(5)

      result = service.send(:database_health)

      expect(result[:connected]).to eq(true)
      expect(result[:response_time]).to eq(15.5)
      expect(result[:connections]).to eq(5)
    end
  end

  describe '#redis_health (private method)' do
    context 'Redisが正常に応答する場合' do
      it 'Redis健全性情報を取得すること' do
        result = service.send(:redis_health)

        expect(result[:connected]).to eq(true)
        expect(result[:response_time]).to be_a(Float)
        expect(result[:memory_usage]).to be_a(Hash)
        expect(result[:status]).to eq('healthy')
      end
    end

    context 'Redis接続でエラーが発生する場合' do
      before do
        allow(Redis).to receive(:new).and_raise(Redis::ConnectionError.new('Connection failed'))
      end

      it 'エラー情報を返すこと' do
        result = service.send(:redis_health)

        expect(result[:connected]).to eq(false)
        expect(result[:status]).to eq('error')
        expect(result[:error]).to include('Connection failed')
      end
    end
  end

  describe '#shlink_api_health (private method)' do
    context 'Shlink APIが設定されており正常な場合' do
      let(:faraday_response) do
        instance_double(Faraday::Response,
          success?: true,
          body: { status: 'pass', version: '3.0.0' }.to_json
        )
      end

      before do
        allow(service).to receive(:shlink_configured?).and_return(true)
        allow(Faraday).to receive(:get).and_return(faraday_response)
      end

      it 'Shlink API健全性情報を取得すること' do
        result = service.send(:shlink_api_health)

        expect(result[:status]).to eq('healthy')
        expect(result[:response_time]).to be_a(Float)
        expect(result[:version]).to eq('3.0.0')
        expect(result[:last_check]).to be_a(Time)
      end
    end

    context 'Shlink APIが設定されていない場合' do
      before do
        allow(service).to receive(:shlink_configured?).and_return(false)
      end

      it 'エラー情報を返すこと' do
        result = service.send(:shlink_api_health)

        expect(result[:status]).to eq('error')
        expect(result[:error]).to eq('Shlink設定が不完全です')
        expect(result[:last_check]).to be_a(Time)
      end
    end
  end

  describe '#background_job_health (private method)' do
    context 'SolidQueueが利用可能な場合' do
      before do
        stub_const('SolidQueue::FailedExecution', double('SolidQueue::FailedExecution', count: 5))
      end

      it 'バックグラウンドジョブ健全性情報を取得すること' do
        result = service.send(:background_job_health)

        expect(result[:failed_jobs]).to eq(5)
        expect(result[:status]).to eq('healthy')
      end
    end

    context '失敗ジョブが多い場合' do
      before do
        stub_const('SolidQueue::FailedExecution', double('SolidQueue::FailedExecution', count: 15))
      end

      it 'warning状態を返すこと' do
        result = service.send(:background_job_health)

        expect(result[:failed_jobs]).to eq(15)
        expect(result[:status]).to eq('warning')
      end
    end
  end

  describe 'helper methods' do
    describe '#format_bytes (private method)' do
      it 'バイト数を適切な単位で表示すること' do
        expect(service.send(:format_bytes, 512)).to eq('512.0 B')
        expect(service.send(:format_bytes, 1536)).to eq('1.5 KB')
        expect(service.send(:format_bytes, 1572864)).to eq('1.5 MB')
        expect(service.send(:format_bytes, 1610612736)).to eq('1.5 GB')
      end
    end

    describe '#memory_status (private method)' do
      it '使用率に基づいて正しいステータスを返すこと' do
        expect(service.send(:memory_status, 50)).to eq('good')
        expect(service.send(:memory_status, 75)).to eq('warning')
        expect(service.send(:memory_status, 90)).to eq('critical')
      end
    end

    describe '#disk_status (private method)' do
      it '使用率に基づいて正しいステータスを返すこと' do
        expect(service.send(:disk_status, 60)).to eq('good')
        expect(service.send(:disk_status, 80)).to eq('warning')
        expect(service.send(:disk_status, 95)).to eq('critical')
      end
    end

    describe '#cpu_status (private method)' do
      it '使用率に基づいて正しいステータスを返すこと' do
        expect(service.send(:cpu_status, 50)).to eq('good')
        expect(service.send(:cpu_status, 80)).to eq('warning')
        expect(service.send(:cpu_status, 95)).to eq('critical')
      end
    end

    describe '#cpu_core_count (private method)' do
      context '/proc/cpuinfoが存在する場合' do
        let(:cpuinfo_content) do
          <<~CPUINFO
            processor	: 0
            processor	: 1
            processor	: 2
            processor	: 3
          CPUINFO
        end

        before do
          allow(File).to receive(:exist?).with("/proc/cpuinfo").and_return(true)
          allow(File).to receive(:read).with("/proc/cpuinfo").and_return(cpuinfo_content)
        end

        it 'CPUコア数を正しく取得すること' do
          expect(service.send(:cpu_core_count)).to eq(4)
        end
      end

      context '/proc/cpuinfoが存在しない場合' do
        before do
          allow(File).to receive(:exist?).with("/proc/cpuinfo").and_return(false)
        end

        it 'デフォルト値の1を返すこと' do
          expect(service.send(:cpu_core_count)).to eq(1)
        end
      end
    end
  end
end
