require 'spec_helper'


describe RealSelf::Stream::Digest::Digest do

  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', 2345)
    @digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
  end


  describe "#new" do
    it "takes three parameters and returns a new instance" do
      expect(@digest).to be_an_instance_of RealSelf::Stream::Digest::Digest
    end

    it "sets protoype when nil" do
      expect(@digest.prototype).to eq('user.digest.notifications')
    end

    it "generates uuid when not provided" do
      expect(@digest.uuid.length).to eq(36)
    end
  end


  describe "#add" do
    it "takes a stream activity and adds it to the summary" do
      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])

      @digest.add(stream_activity)
      hash = @digest.to_h

      expect(hash[:summaries][:thing].length).to eql 1
      thing = RealSelf::Stream::Objekt.from_hash(hash[:summaries][:thing].values[0][0])
      expect(thing).to eql activity.object
    end


    it "takes two stream activities and creates two summaries" do
      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      @digest.add(stream_activity)

      activity2 = Helpers.user_create_thing_activity
      stream_activity2 = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity2,
        [activity2.object])
      @digest.add(stream_activity2)

      hash = @digest.to_h

      expect(hash[:stats][:thing]).to eql 2
      expect(hash[:summaries][:thing].length).to eql 2

      expect(hash[:summaries][:thing][activity.object.id.to_sym][0]).to eql activity.object.to_h
      expect(hash[:summaries][:thing][activity.object.id.to_sym][1]).to be_an_instance_of(Hash)
      expect(hash[:summaries][:thing][activity2.object.id.to_sym][0]).to eql activity2.object.to_h
      expect(hash[:summaries][:thing][activity2.object.id.to_sym][1]).to be_an_instance_of(Hash)
    end


    it "does not store empty summaries" do
      activity = Helpers.user_update_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])

      @digest.add(stream_activity)

      expect(@digest.empty?).to eql true

      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      @digest.add(stream_activity)

      expect(@digest.empty?).to eql false
    end


    it "raises an error when the stream_activity owner does not match the digest owner" do
      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        nil,
        activity,
        [activity.object])

      expect{ @digest.add(stream_activity) }.to raise_error RealSelf::Stream::Digest::Digest::DigestError
    end
  end


  describe "#==" do
    it "compares two identical digests" do
      uuid = SecureRandom.uuid
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400, {}, uuid)
      digest2 = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400, {}, uuid)

      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      digest.add(stream_activity)
      digest2.add(stream_activity)

      activity2 = Helpers.user_create_thing_activity
      stream_activity2 = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity2,
        [activity2.object])
      digest.add(stream_activity2)
      digest2.add(stream_activity2)

      expect(digest).to eql digest2
    end


    it "compares two different digests" do
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
      digest2 = RealSelf::Stream::Digest::Digest.new(:subscriptions, @owner, 86400)

      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      digest.add(stream_activity)
      digest2.add(stream_activity)

      activity2 = Helpers.user_create_thing_activity
      stream_activity2 = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity2,
        [activity2.object])
      digest.add(stream_activity2)
      digest2.add(stream_activity2)

      expect(digest).to_not eql digest2
    end


    it 'compares to nil' do
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
      expect(digest).to_not eql nil
    end


    it 'compares to other object types' do
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
      expect(digest).to_not eql RealSelf::Stream::Objekt.new('user', 1234)
      expect(digest).to_not eql 'string'
      expect(digest).to_not eql({:foo => 'bar'})
      expect(digest).to_not eql Exception.new('oops!')
    end
  end


  describe "#to_s" do
    it "converts the digest to a JSON string" do
      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      @digest.add(stream_activity)

      activity2 = Helpers.user_create_thing_activity
      stream_activity2 = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity2,
        [activity2.object])
      @digest.add(stream_activity2)

      json = @digest.to_s

      hash = MultiJson.decode(json, {:symbolize_keys => true})
      digest = RealSelf::Stream::Digest::Digest.from_json(json)

      expect(hash).to eql @digest.to_h
      expect(@digest).to eql digest
    end
  end


  describe '#content_type' do
    it 'returns the expected content type' do
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
      expect(digest.content_type).to eql RealSelf::ContentType::DIGEST_ACTIVITY
    end
  end


  describe "::from_hash" do
    it "creates a digest from a hash" do
      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      @digest.add(stream_activity)

      hash = @digest.to_h

      digest = RealSelf::Stream::Digest::Digest.from_hash(hash)

      expect(hash).to eql digest.to_h
      expect(@digest).to eql digest
    end
  end


  describe "::from_json" do
    it "creates a digest from a json string" do
      activity = Helpers.user_create_thing_activity
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        activity,
        [activity.object])
      @digest.add(stream_activity)

      json = @digest.to_s

      digest = RealSelf::Stream::Digest::Digest.from_json(json)

      expect(@digest).to eql digest
    end
  end


  describe "#hash" do
    it 'supports hash key equality' do
      d1 = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400, {}, 'uuid')
      d2 = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400, {}, 'uuid')

      expect(d1.object_id).to_not eql(d2.object_id)

      e = {}

      e[d2] = 1234

      expect(e.include?(d1)).to eq(true)
    end
  end

end
