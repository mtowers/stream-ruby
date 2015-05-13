require 'spec_helper'

describe RealSelf::Feed::UnreadCountable do

  class TestUnreadCount
    FEED_NAME = :unread_count_feed_test.freeze
    MAX_FEED_SIZE = 10.freeze
    include RealSelf::Feed::UnreadCountable
  end

  class NoMaxSizeFeed
    FEED_NAME = :unread_count_feed_test.freeze
    include RealSelf::Feed::UnreadCountable
  end


  before(:each) do
    @mongo_db = double('Mongo::DB')
    @mongo_collection = double('Mongo::Collection')

    @owner = RealSelf::Stream::Objekt.new('user', '1234')

    @test_feed = TestUnreadCount.new
    @test_feed.mongo_db = @mongo_db

    @update_statement = {
      :query => {
        :owner_id => @owner.id
      },
      :update => {},
      :upsert => true
    }
  end


  describe "constant assignments" do
    context "use correct constants" do
      it "uses the correct feed name and max size" do
        # declare a class with dissimilar name and size
        # to confirm constants referenced in modules are correct
        class BogusUnreadCountFeed
          FEED_NAME = :bogus_feed_test.freeze
          MAX_FEED_SIZE = 99.freeze
          include RealSelf::Feed::UnreadCountable
        end

        expect(@test_feed.class::FEED_NAME).to eql :unread_count_feed_test
        expect(@test_feed.class::MAX_FEED_SIZE).to eql 10

        expect(BogusCappedFeed::FEED_NAME).to eql :bogus_feed_test
        expect(BogusCappedFeed::MAX_FEED_SIZE).to eql 99
      end
    end
  end


  describe "#decrement_unread_count" do
    before(:each) do
      @update_statement[:query][:count]   = { :'$gt' => 0 }
      @update_statement[:update]          = {:'$inc' => { :count => -1}}
    end


    it "does the update with the correct arguments" do
      expect(@test_feed).to receive(:unread_count_do_update)
        .with(
          @owner,
          @update_statement
        )

        @test_feed.decrement_unread_count(@owner)
    end
  end


  describe "#increment_unread_count" do
    before(:each) do
      @update_statement[:update] = {:'$inc' => { :count => 1}}
    end

    context "max feed size" do
      it "uses the default size when the class does not specify one" do
        @update_statement[:query][:count] = {
          :'$lt' => RealSelf::Feed::UnreadCountable::MAX_UNREAD_COUNT
        }

        @test_feed = NoMaxSizeFeed.new

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(
            @owner,
            @update_statement
          )

          @test_feed.increment_unread_count(@owner)
      end


      it "uses the correct size when the class specifies one" do
        @update_statement[:query][:count] = {
          :'$lt' => 10
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(
            @owner,
            @update_statement
          )

          @test_feed.increment_unread_count(@owner)
      end
    end
  end


  describe "#reset_unread_count" do
    it "delegates to set_unread_count" do
      expect(@test_feed).to receive(:set_unread_count)
        .with(@owner, 0)

      @test_feed.reset_unread_count(@owner)
    end
  end


  describe "#set_unread_count" do
    context "default max feed size" do
      before(:each) do
        @test_feed = NoMaxSizeFeed.new
      end


      it "uses the correct max size if the specified count is too big" do
        max_size = RealSelf::Feed::UnreadCountable::MAX_UNREAD_COUNT

        @update_statement[:update] = {
          :'$set' => {:count => max_size}
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(@owner, @update_statement)

        @test_feed.set_unread_count(@owner, max_size + 1)
      end

      it "rounds negative unread counts to zero" do
        @update_statement[:update] = {
          :'$set' => {:count => 0}
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(@owner, @update_statement)

        @test_feed.set_unread_count(@owner, -1)
      end
    end


    context "explicit max feed size" do
      it "uses the correct max size if the specified count is too big" do
        @update_statement[:update] = {
          :'$set' => {:count => TestUnreadCount::MAX_FEED_SIZE}
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(@owner, @update_statement)

        @test_feed.set_unread_count(@owner, TestUnreadCount::MAX_FEED_SIZE + 1)
      end
    end
  end


  describe "#unread_count_do_update" do
    before(:each) do
      collection_name = "#{@owner.type}.#{TestUnreadCount::FEED_NAME}.unread_count"

      expect(@mongo_db).to receive(:collection)
        .with(collection_name)
        .and_return(@mongo_collection)

      expect(@mongo_collection).to receive(:name)
        .and_return(collection_name)

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with({:owner_id => Mongo::HASHED})

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with({:owner_id => Mongo::DESCENDING}, {:unique => true})
    end


    context "index constraint violation" do
      it "does not raise an error" do
        expect(@mongo_collection).to receive(:find_and_modify)
          .with(instance_of(Hash))
          .and_raise Mongo::OperationFailure.new("error", TestUnreadCount::MONGO_ERROR_DUPLICATE_KEY)

        @test_feed.set_unread_count(@owner, 10)
      end
    end


    context "other mongo errors" do
      it "raises an error" do
        expect(@mongo_collection).to receive(:find_and_modify)
          .with(instance_of(Hash))
          .and_raise Mongo::OperationFailure.new("error", 99999)

        expect{@test_feed.set_unread_count(@owner, 10)}.to raise_error Mongo::OperationFailure
      end
    end
  end

end