require 'spec_helper'

shared_examples '#insertable' do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end

  describe '#insert' do
    it 'inserts activities idempotently' do
      activity  = Helpers.user_create_thing_activity
      sa        = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])

      @feed.insert(@owner, sa)
      expect(@feed.get(@owner)[:count]).to eql 1

      @feed.insert(@owner, sa)
      expect(@feed.get(@owner)[:count]).to eql 1

      activity2 = Helpers.user_create_thing_activity
      sa2       = RealSelf::Stream::StreamActivity.new(@owner, activity2, [@owner])

      @feed.insert(@owner, sa2)
      expect(@feed.get(@owner)[:count]).to eql 2
    end
  end
end
