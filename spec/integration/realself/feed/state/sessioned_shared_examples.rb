require 'spec_helper'
require 'mongo'

shared_examples RealSelf::Feed::State::Sessioned do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
  end


  describe '#touch_session' do
    it 'creates a session' do
      expect(@feed.is_session_alive?(@owner)).to eql false
      @feed.touch_session(@owner)

      expect(@feed.is_session_alive?(@owner)).to eql true
    end

    it 'creates a session with expected time' do
      expect(@feed.is_session_alive?(@owner)).to eql false

      before_sess = BSON::ObjectId.from_time(Time.now)
      sleep 0.25 # sleep a quarter second
      @feed.touch_session(@owner)
      sleep 0.25
      after_sess = BSON::ObjectId.from_time(Time.now)

      before_time = before_sess.generation_time.to_i
      after_time  = after_sess.generation_time.to_i
      session_time = @feed.get_state(@owner)[:last_active].generation_time.to_i

      expect(session_time).to be_within(before_time).of(after_time)
      expect(@feed.is_session_alive?(@owner)).to eql true
    end
  end

  describe '#expire_session' do
    it 'should invalidate a session' do
      @feed.touch_session(@owner)
      expect(@feed.is_session_alive?(@owner)).to eql true
      @feed.expire_session(@owner)
      expect(@feed.is_session_alive?(@owner)).to eql false
    end
  end

  describe '#is_session_alive?' do
    it 'should be dead initailly' do
      expect(@feed.is_session_alive?(@owner)).to eql false
    end
  end

  describe '#set_action_time' do
    it 'will not accept illegal BSON::ObjectId' do
      position = "It's a string!"
      expect{ @feed.send(:set_action_time, @owner, time: position) }.to raise_error(RealSelf::Feed::FeedError)
    end
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:state_collection, @owner.type)
      indexes    = collection.indexes.to_a

      expect(indexes[0][:name]).to eql "_id_"

      expect(indexes[1][:name]).to    eql "owner_id_-1"
      expect(indexes[1][:key]).to     eql({'owner_id' => Mongo::Index::DESCENDING})
      expect(indexes[1][:unique]).to  eql true
    end
  end
end
