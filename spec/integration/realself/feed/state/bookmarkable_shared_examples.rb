require 'spec_helper'
require 'mongo'

shared_examples RealSelf::Feed::State::Bookmarkable do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
    @position = BSON::ObjectId.from_time(Time.now)
  end


  describe '#get_bookmark' do
    it 'will return nil when there is no bookmark' do
      expect(@feed.get_bookmark(@owner, :no_key)).to be_nil
    end
  end

  describe '#set_bookmark' do
    it 'bookmark/set a position with valid BSON::ObjectId' do
      set_pos = @feed.set_bookmark(@owner, @position, :test_cursor)
      get_pos = @feed.get_bookmark(@owner, :test_cursor)

      expect(set_pos).to eql get_pos
      expect(@position).to eql set_pos
    end

    it 'will not accept illegal BSON::ObjectId' do
      position = "It's a string!"
      expect{ @feed.set_bookmark(@owner, :cursor, position) }.to raise_error(RealSelf::Feed::FeedError)
    end

    it 'can handle multiple key with different position' do
      position_1 = BSON::ObjectId.from_time(Time.now)
      position_2 = BSON::ObjectId.from_time(Time.now + 2000)
      @feed.set_bookmark(@owner, position_1)
      @feed.set_bookmark(@owner, position_2, :seconds_later)

      expect(@feed.get_bookmark(@owner)).to eql position_1
      expect(@feed.get_bookmark(@owner, :seconds_later)).to eql position_2
    end
  end

  describe '#remove_bookmark' do
    it 'does nothing when there are no bookmark initially' do
      expect(@feed.get_bookmark(@owner, :key_does_not_exist)).to be_nil
      @feed.remove_bookmark(@owner, :key_does_not_exist)
      expect(@feed.get_bookmark(@owner, :key_does_not_exist)).to be_nil
    end

    it 'removes a bookmark' do
      @feed.set_bookmark(@owner, @position, :position)
      expect(@feed.get_bookmark(@owner, :position)).to eql @position
      @feed.remove_bookmark(@owner, :position)
      expect(@feed.get_bookmark(@owner, :position)).to be_nil
    end

    it 'should not remove another bookmark' do
      position_1 = BSON::ObjectId.from_time(Time.now)
      position_2 = BSON::ObjectId.from_time(Time.now + 2000)
      @feed.set_bookmark(@owner, position_1, :time_now)
      @feed.set_bookmark(@owner, position_2, :time_seconds_later)

      @feed.remove_bookmark(@owner, :time_now)

      expect(@feed.get_bookmark(@owner, :time_now)).to be nil
      expect(@feed.get_bookmark(@owner, :time_seconds_later)).to eql position_2
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
