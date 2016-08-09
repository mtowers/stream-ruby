require 'spec_helper'
require 'mongo'

describe RealSelf::Feed::Capped do

  class StatefulCappedIntegrationTestFeed < RealSelf::Feed::Capped
    FEED_NAME = :stateful_capped_integration_test.freeze
    MAX_FEED_SIZE = 10.freeze
    SESSION_EXPIRE_AFTER_SECONDS = 2.freeze
    include RealSelf::Feed::Stateful
  end


  before :all do
    @feed           = StatefulCappedIntegrationTestFeed.new
    @feed.mongo_db  = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end


  # shared examples
  it_should_behave_like '#insertable', @feed
  it_should_behave_like RealSelf::Feed::Stateful, @feed


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
    @activity         = Helpers.user_create_thing_activity
    @stream_activity  = RealSelf::Stream::StreamActivity.new(@owner, @activity, [@owner])
  end


  describe "constant assignments" do
    context "use correct constants" do
      it "uses the correct feed name and max size" do
        # declare a class with dissimilar name and size
        # to confirm constants referenced in modules are correct
        class BogusCappedFeed < RealSelf::Feed::Capped
          FEED_NAME = :bogus_feed_test.freeze
          MAX_FEED_SIZE = 99.freeze
        end

        feed = StatefulCappedIntegrationTestFeed.new

        expect(feed.class::FEED_NAME).to eql :stateful_capped_integration_test
        expect(feed.class::MAX_FEED_SIZE).to eql 10

        expect(BogusCappedFeed::FEED_NAME).to eql :bogus_feed_test
        expect(BogusCappedFeed::MAX_FEED_SIZE).to eql 99
      end
    end
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:get_collection, @owner.type)
      indexes    = collection.indexes.to_a

      result = indexes.map do |index|
        case index[:name]
        when "_id_"
          index[:name]
        when "feed.activity.uuid_-1"
          index[:name]
        when "object.id_-1"
          expect(index[:key]).to eql({'object.id' => Mongo::Index::DESCENDING})
          index[:name]
        end
      end.compact

      expect(result.size).to eql 3
    end
  end


  describe "feed composition" do
    context "illegal composition" do
      it "disallows Capped feeds to be mixed in with Redactable feeds" do
        expect{
          class IllegalCompositionFeed < RealSelf::Feed::Capped
            include RealSelf::Feed::Redactable
          end
        }.to raise_error(RealSelf::Feed::FeedError, /Redactable/)
      end

      it "disallows Getable feeds to be mixed in with Capped feeds" do
        expect{
          class IllegalCompositionFeed < RealSelf::Feed::Capped
            include RealSelf::Feed::Getable
          end
        }.to raise_error(RealSelf::Feed::FeedError, /Getable/)
      end
    end
  end

  describe "#is_session_alive?" do
    it "should expire after 2 second" do
      @feed.touch_session(@owner)
      expect(@feed.is_session_alive?(@owner)).to be true
      sleep(@feed.class::SESSION_EXPIRE_AFTER_SECONDS - 1)
      expect(@feed.is_session_alive?(@owner)).to be true
      sleep(1)
      expect(@feed.is_session_alive?(@owner)).to be false
    end
  end

  describe '#insert' do
    it "limits the feed to the specified max size" do
      stream_activities = []

      (StatefulCappedIntegrationTestFeed::MAX_FEED_SIZE + 1).times do
        activity = Helpers.user_create_thing_activity
        sa       = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])

        stream_activities << sa
        @feed.insert @owner, sa
      end

      result = @feed.get @owner, StatefulCappedIntegrationTestFeed::MAX_FEED_SIZE + 1

      expect(StatefulCappedIntegrationTestFeed::MAX_FEED_SIZE == result[:unread_count])
      expect(result[:stream_items].count).to eql StatefulCappedIntegrationTestFeed::MAX_FEED_SIZE

      stream_activities.reverse!

      result[:stream_items].each_index do |index|
        expect(stream_activities[index]).to eql RealSelf::Stream::StreamActivity.from_hash(result[:stream_items][index].to_hash)
      end
    end


    it "allows duplicates" do
      @feed.insert @owner, @stream_activity, true
      @feed.insert @owner, @stream_activity, true

      result = @feed.get @owner, 2

      result[:stream_items][0].delete 'id'
      result[:stream_items][1].delete 'id'

      expect(result[:stream_items][0]).to eql result[:stream_items][1]
    end


    it "disallows duplicates" do
      @feed.insert @owner, @stream_activity, false, {'activity.object' => @activity.object.to_h}
      @feed.insert @owner, @stream_activity, false, {'activity.object' => @activity.object.to_h}

      result = @feed.get @owner, 2

      expect(result[:count]).to eql 1
    end
  end
end
