require 'spec_helper'
require 'mongo'

shared_examples RealSelf::Feed::State::UnreadCountable do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
  end


  describe '#decrement_unread_count' do
    it 'decrements the unread count' do
      set_count = @feed.set_unread_count(@owner, 10)[:unread_count]
      dec_count = @feed.decrement_unread_count(@owner)[:unread_count]

      expect(set_count - 1).to eql dec_count
      expect(dec_count).to eql 9
    end

    it 'will not decrement below zero' do
      set_count = @feed.set_unread_count(@owner, 0)[:unread_count]
      dec_count = @feed.decrement_unread_count(@owner)[:unread_count]

      expect(set_count).to eql 0
      expect(dec_count).to eql 0
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


  describe '#find_with_unread' do
    before :each do
      @owner_2 = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
      @owner_3 = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))

      @feed.set_unread_count(@owner, 5)[:unread_count]
      @feed.set_unread_count(@owner_2, 10)[:unread_count]
    end
    it 'finds objects with an unread count greater than zero' do
      owners = @feed.find_with_unread(:user)

      ids = owners.map { |o| o[:owner_id] }

      expect(ids.include? @owner.id).to   eql true
      expect(ids.include? @owner_2.id).to  eql true
      expect(ids.include? @owner_3.id).to  eql false
    end


    it 'finds objects with an unread count greater than the specified value' do
      owners = @feed.find_with_unread(:user, 6)

      ids = owners.map { |o| o[:owner_id] }

      expect(ids.include? @owner.id).to   eql false
      expect(ids.include? @owner_2.id).to eql true
      expect(ids.include? @owner_3.id).to eql false
    end


    it 'limits the number of returned objects to the specified value' do
      owner_count = @feed.find_with_unread(:user, 1).count
      limit_count = @feed.find_with_unread(:user, 1, 2).count

      expect(owner_count > limit_count).to eql true
      expect(limit_count).to eql 2
    end


    it 'returns results with an id greater than the specified value' do
      owners      = @feed.find_with_unread :user
      owner_count = owners.count
      last_id     = owners[0][:id]
      owners      = @feed.find_with_unread :user, 1, 100, last_id
      ids         = owners.map { |o| o[:owner_id] }

      expect(owner_count - 1).to      eql owners.count
      expect(ids.include? last_id).to eql false
    end
  end


  describe '#increment_unread_count' do
    it 'increments the unread count' do
      set_count = @feed.set_unread_count(@owner, 5)[:unread_count]
      inc_count = @feed.increment_unread_count(@owner)[:unread_count]

      expect(set_count + 1).to eql inc_count
      expect(inc_count).to eql 6
    end


    it 'will not increment beyond the max feed size' do
      set_count = @feed.set_unread_count(@owner, @feed.class::MAX_FEED_SIZE)[:unread_count]
      inc_count = @feed.increment_unread_count(@owner)[:unread_count]

      expect(set_count).to eql @feed.class::MAX_FEED_SIZE
      expect(inc_count).to eql @feed.class::MAX_FEED_SIZE
    end
  end


  describe '#reset_unread_count' do
    it 'sets the unread count to zero' do
      set_count   = @feed.set_unread_count(@owner, 5)[:unread_count]
      reset_count = @feed.reset_unread_count(@owner)[:unread_count]
      get_count   = @feed.get_unread_count(@owner)[:unread_count]

      expect(5).to eql set_count
      expect(0).to eql reset_count
      expect(0).to eql get_count
    end
  end


  describe '#set_unread_count' do
    it 'sets the unread count' do
      set_count = @feed.set_unread_count(@owner, 5)[:unread_count]
      get_count = @feed.get_unread_count(@owner)[:unread_count]

      expect(5).to eql set_count
      expect(5).to eql get_count
    end


    it 'will not set the unread count to less than zero' do
      set_count = @feed.set_unread_count(@owner, -5)[:unread_count]
      get_count = @feed.get_unread_count(@owner)[:unread_count]

      expect(0).to eql set_count
      expect(0).to eql get_count
    end


    it 'will not set the unread count to greater than MAX_FEED_SIZE' do
      set_count = @feed.set_unread_count(@owner, @feed.class::MAX_FEED_SIZE + 1)[:unread_count]
      get_count = @feed.get_unread_count(@owner)[:unread_count]

      expect(@feed.class::MAX_FEED_SIZE).to eql set_count
      expect(@feed.class::MAX_FEED_SIZE).to eql get_count
    end
  end
end
