RSpec.configure do |c|
  c.include Helpers
end

describe RealSelf::Stream::Factory do

  before :each do
    @owner = RealSelf::Stream::Objekt.new('dr', 2345)
    @digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)

    @activity = RealSelf::Stream::Activity.new(
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      @owner,
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      RealSelf::Stream::Objekt.new('question', 3456),
      {},
      'f364c40c-6e91-4064-a825-faae79c10254',
      'explicit.prototype.value')

    @followed_activity = RealSelf::Stream::FollowedActivity.new(
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      @owner,
      'author',
      RealSelf::Stream::FollowedObjekt.new('answer', 2345),
      RealSelf::Stream::FollowedObjekt.new('question', 3456),
      {},
      'f364c40c-6e91-4064-a825-faae79c10254',
      'explicit.prototype.value')

    @stream_activity = RealSelf::Stream::StreamActivity.new(
      @owner,
      @activity,
      [RealSelf::Stream::Objekt.new('dr', 1234),
       RealSelf::Stream::Objekt.new('topic', 4567)])
  end

  describe "#self.from_hash" do

    it "raises an error for unknown content types" do
      expect{RealSelf::Stream::Factory.from_hash('bogus-type', {})}.to raise_error RealSelf::ContentTypeError
    end

    it "creates an activity" do
      activity = RealSelf::Stream::Factory.from_hash(
        RealSelf::ContentType::ACTIVITY,
        @activity.to_h
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
    end

    it "creates a digest" do
      activity = RealSelf::Stream::Factory.from_hash(
        RealSelf::ContentType::DIGEST_ACTIVITY,
        @digest.to_h
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::Digest::Digest
    end


    it "creates a followed activity" do
      activity = RealSelf::Stream::Factory.from_hash(
        RealSelf::ContentType::FOLLOWED_ACTIVITY,
        @followed_activity.to_h
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::FollowedActivity
    end


    it "creates a stream activity" do
      activity = RealSelf::Stream::Factory.from_hash(
        RealSelf::ContentType::STREAM_ACTIVITY,
        @stream_activity.to_h
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::StreamActivity
    end

  end


  describe "#self.from_json" do

    it "raises an error for unknown content types" do
      expect{RealSelf::Stream::Factory.from_json('bogus-type', '')}.to raise_error RealSelf::ContentTypeError
    end

    it "creates an activity" do
      activity = RealSelf::Stream::Factory.from_json(
        RealSelf::ContentType::ACTIVITY,
        @activity.to_s
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
    end

    it "creates a digest" do
      activity = RealSelf::Stream::Factory.from_json(
        RealSelf::ContentType::DIGEST_ACTIVITY,
        @digest.to_s
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::Digest::Digest
    end

    it "creates a followed activity" do
      activity = RealSelf::Stream::Factory.from_json(
        RealSelf::ContentType::FOLLOWED_ACTIVITY,
        @followed_activity.to_s
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::FollowedActivity
    end

    it "creates a stream activity" do
      activity = RealSelf::Stream::Factory.from_json(
        RealSelf::ContentType::STREAM_ACTIVITY,
        @stream_activity.to_s
      )

      expect(activity).to be_an_instance_of RealSelf::Stream::StreamActivity
    end

  end

end

