require 'spec_helper'

describe RealSelf::Stream::FollowedActivity do


  before :each do
    @followed_activity = RealSelf::Stream::FollowedActivity.from_json(
      MultiJson.encode(Helpers.followed_activity_hash(1234)))
  end


  describe "#to_h" do
    it "returns a hash representation of the followed activity" do
      hash = Helpers.followed_activity_hash(1234)
      expect(@followed_activity.to_h).to eql hash
    end
  end


  describe "::from_json" do
    it "can create a followed_activity" do
      followed_activity = RealSelf::Stream::FollowedActivity.from_json(
        MultiJson.encode(Helpers.followed_activity_hash(1234)))

      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivity
    end
  end


  describe "::from_hash" do
    it "can create a followed_activity" do
      followed_activity = RealSelf::Stream::FollowedActivity.from_hash(Helpers.followed_activity_hash(1234))
      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivity
    end

    it "can create a followed_activity with a date string in the hash" do
      hash = Helpers.followed_activity_hash(1234)
      hash[:published] = hash[:published].to_s
      followed_activity = RealSelf::Stream::FollowedActivity.from_hash(hash)
      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivity
    end
  end


  describe '#content_type' do
    it 'returns the correct content_type' do
      expect(@followed_activity.content_type). to eql RealSelf::ContentType::FOLLOWED_ACTIVITY
    end
  end


  describe "#hash" do
    it "supports hash key equality" do
      fa1 = RealSelf::Stream::FollowedActivity.from_hash(Helpers.followed_activity_hash(1234))
      fa2 = RealSelf::Stream::FollowedActivity.from_hash(Helpers.followed_activity_hash(1234))

      expect(fa1.object_id).to_not eql(fa2.object_id)
      e = {}

      e[fa1] = 123

      expect(e.include?(fa2)).to eql(true)
    end
  end


  describe "#map_followers" do
    it "enumerates all followers of the activity and describes the reason the follower was included" do
      followers_map = {}
      @followed_activity.map_followers do |follower, reason|
        followers_map[reason] = [] if followers_map[reason].nil?
        followers_map[reason] << follower
      end

      followers_map.each do |reason, followers|
        if 'dr' == reason.type
          expect(followers.length).to eql 2
          expect(followers).to include(RealSelf::Stream::Objekt.new('dr', 1234))
          expect(followers).to include(RealSelf::Stream::Objekt.new('user', 2345))
        end

        if 'answer' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('answer', 1050916),
            RealSelf::Stream::Objekt.new('user', 3456),
            RealSelf::Stream::Objekt.new('user', 4567)
          )
        end

        if 'question' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('question', 1048591),
            RealSelf::Stream::Objekt.new('user', 5678),
            RealSelf::Stream::Objekt.new('user', 6789)
          )
        end

        if 'topic' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('topic', 265299),
            RealSelf::Stream::Objekt.new('user', 7890),
            RealSelf::Stream::Objekt.new('user', 8901)
          )
        end
      end
    end
  end


  describe "#to_activity" do
    it "creates an Activity object from a FollowedActivity" do
      followed_activity = RealSelf::Stream::FollowedActivity.from_json(
        MultiJson.encode(Helpers.followed_activity_hash(1234)))
      activity          = followed_activity.to_activity

      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
      expect(followed_activity.title).to eql activity.title

      expect(followed_activity.actor.to_objekt).to eql activity.actor
      expect(followed_activity.verb).to eql activity.verb
      expect(followed_activity.object.to_objekt).to eql activity.object
      expect(followed_activity.target.to_objekt).to eql activity.target
      expect(followed_activity.uuid).to eql activity.uuid
      expect(followed_activity.prototype).to eql activity.prototype
      expect(activity.version).to eql 2

      followed_activity.extensions.each do |key, obj|
        expect(obj.to_objekt).to eql activity.extensions[key]
      end
    end
  end
end
