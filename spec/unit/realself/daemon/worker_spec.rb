require 'spec_helper'

describe RealSelf::Daemon::Worker do

    module TestEnclosure
      def self.handle
        yield
        :ack
      end
    end


    class TestHandler
      include RealSelf::Handler::Activity
      register_handler('test.activity')

      def initialize(test_handler:)
      end

      def handle(activity)
      end
    end

  before(:all) do
    RealSelf::Handler::Factory.register_enclosure('worker.test', RealSelf::Handler::Enclosure)
  end


  before(:each) do
    @worker_options = {
       :ack         => true,
       :durable     => true,
       :exchange    => 'test.exchange',
       :prefetch    => 1,
       :routing_key => ['test.activity'],
       :threads     => 1,
       :arguments   => {:'x-dead-letter-exchange' => "test.queue-retry"}
    }
  end

  context '#configure' do
    it 'sets the worker options correctly' do
      expect(RealSelf::Daemon::ActivityWorker).to receive(:from_queue)
        .with('test.queue', @worker_options)

      RealSelf::Daemon::ActivityWorker.configure({
        :exchange_name => 'test.exchange',
        :queue_name    => 'test.queue',
        :enable_retry  => true
      })
    end

    it 'honors passed worker param overriedes' do
      @worker_options[:timeout_job_after] = 60

      expect(RealSelf::Daemon::ActivityWorker).to receive(:from_queue)
        .with('test.queue', @worker_options)

      RealSelf::Daemon::ActivityWorker.configure({
        :exchange_name => 'test.exchange',
        :queue_name    => 'test.queue',
        :enable_retry  => true,
        :worker_options => {
          :timeout_job_after => 60
        }
      })
    end


    it 'loggs a warning if there are no handlers registered' do
      expect(RealSelf.logger).to receive(:warn)
        .with(/stream_activity\+json/)

      # StreamActivityWorker has no handlers in this context
      RealSelf::Daemon::StreamActivityWorker.configure({
        :exchange_name => 'test.exchange',
        :queue_name    => 'test.queue',
        :enable_retry  => true
      })
    end
  end


  context '#work_with_params' do
    before(:each) do
      @activity = RealSelf::Stream::Activity.new(
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('test', 0),
        'ack',
        RealSelf::Stream::Objekt.new('message', 0),
        nil,
        nil,
        SecureRandom.uuid,
        'test.activity')
    end


    it 'calls initializes state and calls handle on the hander(s)' do
      expect(RealSelf::Daemon::ActivityWorker).to receive(:from_queue)
        .with('test.queue', @worker_options)
        .and_call_original

      expect(RealSelf::Stream::Factory).to receive(:from_json)
        .and_return(@activity)

      expect(RealSelf::Handler::Factory).to receive(:enclosure)
        .with('test.queue')
        .and_call_original

      expect(RealSelf::Handler::Factory).to receive(:create)
        .with(
          'test.activity',
          RealSelf::ContentType::ACTIVITY,
          {:test_handler => 'param1'})
        .and_call_original

      expect_any_instance_of(TestHandler).to receive(:handle)
        .with(@activity)

      RealSelf::Daemon::ActivityWorker.configure({
        :enable_retry       => true,
        :enclosure          => TestEnclosure,
        :exchange_name      => 'test.exchange',
        :queue_name         => 'test.queue',
        :handler_params     => {:test_handler => 'param1'}
      })

      worker = RealSelf::Daemon::ActivityWorker.new

      worker.work_with_params(@activity.to_s, nil, nil)
    end
  end

end
