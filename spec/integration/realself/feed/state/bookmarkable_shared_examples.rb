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
      expect(@feed.get_bookmark(@owner)).to be_nil
    end
  end

  describe '#set_bookmark' do
    it 'bookmark/set a position with valid BSON::ObjectId' do
      set_pos = @feed.set_bookmark(@owner, @position)
      get_pos = @feed.get_bookmark(@owner)

      expect(set_pos).to eql get_pos
      expect(@position).to eql set_pos
    end

    it 'will not accept illegal BSON::ObjectId' do
      position = "It's a string!"
      expect{ @feed.set_bookmark(@owner, position) }.to raise_error(RealSelf::Feed::FeedError)
    end
  end

  describe '#remove_bookmark' do
    it 'does nothing when there are no bookmark initially' do
      expect(@feed.get_bookmark(@owner)).to be_nil
      @feed.remove_bookmark(@owner)
      expect(@feed.get_bookmark(@owner)).to be_nil
    end

    it 'removes a bookmark' do
      @feed.set_bookmark(@owner, @position)
      expect(@feed.get_bookmark(@owner)).to eql @position
      @feed.remove_bookmark(@owner)
      expect(@feed.get_bookmark(@owner)).to be_nil
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
