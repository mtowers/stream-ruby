require 'spec_helper'


describe RealSelf::Stream::Publisher do

  before :each do
    @bunny_session  = double(Bunny::Session)
    @bunny_channel  = double(Bunny::Channel)
    @bunny_exchange = double(Bunny::Exchange)
    @exchange_name  = 'test.exchange'
    @rmq_config     = {
      :heartbeat  => 60,
      :host       => 'localhost',
      :password   => 'guest',
      :port       => 5672,
      :user       => 'guest',
      :vhost      => '/'
    }
  end


  context '#publish' do
    before :each do
      @activity  = Helpers.user_create_thing_activity
      @publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)

      expect(Bunny).to receive(:new)
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)

      expect(@bunny_session).to receive(:create_channel)
        .once
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:confirm_select)

      expect(@bunny_channel).to receive(:topic)
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)

      allow(@bunny_exchange).to receive(:publish)
        .with(
          @activity.to_s,
          :content_type => 'application/json',
          :message_id   => @activity.hash,
          :persistent   => true,
          :routing_key  => @activity.prototype)

      expect(@bunny_channel).to receive(:wait_for_confirms)
    end


    it 'publishes an activity' do
      expect(@bunny_channel).to receive(:nacked_set)
        .and_return(Set.new)

      @publisher.publish(@activity)
    end


    it 'publishes multiple activities' do
      activities = []
      10.times do
        activities << Helpers.user_create_thing_activity
      end

      expect(@bunny_exchange).to receive(:publish)
        .exactly(10)
        .times

      expect(@bunny_channel).to receive(:nacked_set)
        .and_return(Set.new)

      @publisher.publish(activities)
    end


    it 'raises an error if confirmations are not received' do
      expect(@bunny_channel).to receive(:nacked_set)
        .and_return(Set.new([@activity.hash]))

      expect(RealSelf::logger).to receive(:error)

      expect{@publisher.publish(@activity)}.to raise_error RealSelf::Stream::PublisherError
    end
  end


  context '#publish with network error' do
    it 'retries the publish if a network error is encountered' do
      @activity   = Helpers.user_create_thing_activity
      @nfe        = ::Bunny::NetworkFailure.new("a bad thing happened", nil)
      @publisher  = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)

      expect(Bunny).to receive(:new)
        .exactly(4)
        .times
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)
        .exactly(4)
        .times


      expect(@bunny_session).to receive(:create_channel)
        .exactly(4)
        .times
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:confirm_select)
        .exactly(4)
        .times

      expect(@bunny_channel).to receive(:topic)
        .exactly(4)
        .times
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)

      expect(@bunny_exchange).to receive(:publish)
        .exactly(4)
        .times
        .with(
          @activity.to_s,
          :content_type => 'application/json',
          :message_id   => @activity.hash,
          :persistent   => true,
          :routing_key  => @activity.prototype)
        .and_raise(@nfe)

      expect{@publisher.publish(@activity)}.to raise_error(@nfe)
    end
  end

  context '#publish with timeout error' do
    it 'invalidates the connection and then raises the Timeout::Error' do
      @activity   = Helpers.user_create_thing_activity
      @te         = ::Timeout::Error.new("the publish timed out")
      @publisher  = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)


      expect(Bunny).to receive(:new)
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)

      expect(@bunny_session).to receive(:create_channel)
        .once
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:confirm_select)

      expect(@bunny_channel).to receive(:topic)
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)

      allow(@bunny_exchange).to receive(:publish)
        .with(
          @activity.to_s,
          :content_type => 'application/json',
          :message_id   => @activity.hash,
          :persistent   => true,
          :routing_key  => @activity.prototype)

      expect(@bunny_channel).to receive(:wait_for_confirms)
        .and_raise(@te)

      expect{@publisher.publish(@activity)}.to raise_error(@te)
    end
  end
end
