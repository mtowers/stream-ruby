require 'spec_helper'

shared_examples RealSelf::Feed::Stateful do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end

  it_should_behave_like RealSelf::Feed::State::Bookmarkable, @feed
  it_should_behave_like RealSelf::Feed::State::Sessioned, @feed
  it_should_behave_like RealSelf::Feed::State::UnreadCountable, @feed

  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
    @bookmark = BSON::ObjectId.from_time(Time.now)
  end

  describe '#get_state' do
    context 'when state does not exists' do
      it 'should return a hash containing owners id' do
        states = @feed.get_state(@owner)
        expect(states["owner_id"]).to eql @owner.id
        expect(["owner_id"] - states.keys).to be_empty # hash only has one key
      end
    end

    context 'when state exists' do
      it 'should return all states' do
        @feed.set_bookmark(@owner, @bookmark)
        states = @feed.get_state(@owner)
        expect(["_id", "owner_id", "position"] - states.keys).to be_empty
      end

      it 'should not affect other states' do
        @feed.set_bookmark(@owner, @bookmark)
        @feed.touch_session(@owner)
        states = @feed.get_state(@owner)
        expect(["_id", "owner_id", "position", "last_active"] - states.keys).to be_empty
      end
    end
  end

  describe '#increment_unread_count' do
    context 'when state document exists, and count field does not' do
      it 'will successfully create and increment count' do
        @feed.set_bookmark @owner, @bookmark

        states = @feed.get_state(@owner)
        expect(states[:position]).to eql @bookmark
        expect(states[:unread_count]).to be_nil

        @feed.increment_unread_count @owner
        states = @feed.get_state(@owner)
        expect(states[:position]).to eql @bookmark
        expect(states[:unread_count]).to eql 1
      end
    end
  end
end
