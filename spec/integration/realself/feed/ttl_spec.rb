require 'spec_helper'

describe RealSelf::Feed::Ttl do
  include Helpers

  class TestTtl < RealSelf::Feed::Ttl
    FEED_NAME = :ttl_integrtion_test.freeze
    FEED_TTL_SECONDS = 60.freeze
    include RealSelf::Feed::UnreadCountable
    include RealSelf::Feed::Redactable
  end


  before :all do
    @feed           = TestTtl.new
    @feed.mongo_db  = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end

  it_should_behave_like '#insertable', @feed
  it_should_behave_like RealSelf::Feed::Getable, @feed
  it_should_behave_like RealSelf::Feed::Redactable, @feed
  it_should_behave_like RealSelf::Feed::UnreadCountable, @feed


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:get_collection, @owner.type)
      indexes    = collection.indexes.to_a

      result = indexes.map do |index|
        case index[:name]
        when "_id_"
          index[:name]
        when "object.id_-1__id_-1"
          expect(index[:key]).to eql({
            'object.id' => Mongo::Index::DESCENDING,
            '_id'       => Mongo::Index::DESCENDING})
          expect(index[:unique]).to eql true
          index[:name]
        when "activity.uuid_-1_object.id_-1"
          expect(index[:key]).to eql({
            'activity.uuid'  => Mongo::Index::DESCENDING,
            'object.id'      => Mongo::Index::DESCENDING})
          expect(index[:unique]).to eql true
          index[:name]
        when "activity.published_-1"
          expect(index[:expireAfterSeconds]).to eql @feed.class::FEED_TTL_SECONDS
          index[:name]
        end
      end.compact

      expect(result.size).to eql 4
    end
  end


  describe '#insert' do
    it 'adds entries with published attribute of the correct type' do
      activity  = Helpers.user_create_thing_activity
      sa        = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])

      @feed.insert(@owner, sa)
      result = @feed.get @owner

      created = result[:stream_items][0][:activity][:published]
      expect(created).to_not eql nil
      expect(created).to be_instance_of(Time)
    end


    it 'expires old activities' do
      unless IntegrationHelper.skip_ttl_test
        activity  = Helpers.user_create_thing_activity
        sa        = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])

        @feed.insert(@owner, sa)
        expect(@feed.get(@owner)[:count]).to eql 1


        puts "Waiting 100 secs for TTL to expire..."
        100.times do |num|
          print("#{100 - num}.")
          sleep(1)
        end

        feed = TestTtl.new
        feed.mongo_db = Mongo::Database.new(Mongo::Client.new('mongodb://localhost:27017'), @feed.mongo_db.name)

        expect(@feed.get(@owner)[:count]).to eql 0
      end
    end
  end
end
