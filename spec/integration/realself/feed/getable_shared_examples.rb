require 'spec_helper'

shared_examples RealSelf::Feed::Getable do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
  end


  describe '#get' do
    context 'default arguments' do
      it 'executes the query and returns a properly formatted response' do
        result = @feed.get @owner

        expect(0    == result[:count])
        expect(nil  == result[:after])
        expect(nil  == result[:before])
        expect(0    == result[:stream_items].count)
      end
    end


    context 'paging' do
      before :each do
        # insert some activities
        5.times do
          activity = Helpers.user_create_thing_activity
          sa       = RealSelf::Stream::StreamActivity.new(
            @owner,
            activity,
            [@owner])

          @feed.insert @owner, sa
        end
      end


      it 'returns items before a given item' do
        result  = @feed.get @owner, 2
        before  = result[:stream_items][0][:id]
        next_id = result[:stream_items][1][:id]
        result  = @feed.get @owner, nil, before
        id      = result[:stream_items][0][:id]

        before_oid  = BSON::ObjectId.from_string(before)
        next_oid    = BSON::ObjectId.from_string(next_id)
        oid         = BSON::ObjectId.from_string(id)

        expect(next_oid).to eql oid
        expect(before_oid > next_oid).to eql true
      end


      it 'returns items after a given item' do
        result    = @feed.get @owner
        after     = result[:stream_items][result[:count]-1][:id]
        next_id   = result[:stream_items][result[:count]-2][:id]
        result    = @feed.get @owner, nil, nil, after
        id        = result[:stream_items][result[:count]-1][:id]

        after_oid = BSON::ObjectId.from_string(after)
        next_oid  = BSON::ObjectId.from_string(next_id)
        oid       = BSON::ObjectId.from_string(id)

        expect(next_oid).to eql oid
        expect(after_oid < next_oid).to eql true
      end


      it 'returns items beetween two items' do
        result  = @feed.get @owner
        before  = result[:stream_items][0][:id]
        prev_id = result[:stream_items][1][:id]
        after   = result[:stream_items][result[:count]-1][:id]
        next_id = result[:stream_items][result[:count]-2][:id]

        before_oid  = BSON::ObjectId.from_string(before)
        prev_oid    = BSON::ObjectId.from_string(prev_id)
        after_oid   = BSON::ObjectId.from_string(after)
        next_oid    = BSON::ObjectId.from_string(next_id)

        result  = @feed.get @owner, nil, before, after
        first   = result[:stream_items][0][:id]
        last    = result[:stream_items][result[:count]-1][:id]

        first_oid = BSON::ObjectId.from_string(first)
        last_oid  = BSON::ObjectId.from_string(last)

        expect(prev_oid).to eql first_oid
        expect(next_oid).to eql last_oid
        expect(first_oid > last_oid).to eql true
      end


      it 'filters the owner from returned stream activities' do
        result = @feed.get @owner, nil, nil, nil, {}, false

        result[:stream_items].each do |item|
          expect(item.has_key? :object).to eql false
        end
      end


      it 'executes passed filters' do
          activity = Helpers.user_update_thing_activity
          sa       = RealSelf::Stream::StreamActivity.new(
            @owner,
            activity,
            [@owner])

          @feed.insert @owner, sa

          query   = {:'activity.prototype' => 'user.update.thing'}
          result  = @feed.get @owner, nil, nil, nil, query

          expect(result[:count]).to eql 1
          expect(result[:stream_items][0][:activity][:prototype]).to eql 'user.update.thing'
      end
    end
  end
end
