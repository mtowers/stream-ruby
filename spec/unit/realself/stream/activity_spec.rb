require 'spec_helper'


describe RealSelf::Stream::Activity do

  before :each do
    @activity = RealSelf::Stream::Activity.from_json(Helpers.example_activity.to_s)
  end


  describe "::from_json" do

    it "can create an activity" do
      json = MultiJson.encode(Helpers.example_hash)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
      expect(activity.version).to eql 2
    end

    it "raises an exception on parse error" do
      hash = Helpers.example_hash
      hash[:published] = "bogus date"
      json = MultiJson.encode(hash)
      expect{RealSelf::Stream::Activity.from_json(json)}.to raise_error JSON::Schema::ValidationError
    end
  end


  describe "::from_hash" do

    it "can create an activity" do
      activity = RealSelf::Stream::Activity.from_hash(Helpers.example_hash)
      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
      expect(activity.version).to eql 2
    end

    it "can create an activity with a date string in the hash" do
      hash = Helpers.example_hash
      hash[:published] = hash[:published].to_s
      activity = RealSelf::Stream::Activity.from_hash(hash)
      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
      expect(activity.version).to eql 2
    end
  end


  describe "#new" do

    it "creates an activity object" do
      activity = RealSelf::Stream::Activity.new(
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        {:topic => RealSelf::Stream::Objekt.new('topic', 4567)},
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value")

      expect(activity).to be_an_instance_of RealSelf::Stream::Activity
    end

    it "fails to create an activity object with an invalid UUID" do
      expect{RealSelf::Stream::Activity.new(
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        nil,  #invalid
        "bogus-uuid-value",
        "explicit.prototype.value"
      )}.to raise_error ArgumentError
    end
  end


  describe '#==' do
    it 'compares two activities' do
      activity  = Helpers.example_activity
      other     = Helpers.example_activity

      expect(activity).to eql other
    end

    it 'compares to nil' do
      activity = Helpers.example_activity
      expect(activity).to_not eql nil
    end

    it 'compares to other object types' do
      activity = Helpers.example_activity
      expect(activity).to_not eql RealSelf::Stream::Objekt.new('user', 1234)
      expect(activity).to_not eql 'string'
      expect(activity).to_not eql({:foo => 'bar'})
      expect(activity).to_not eql Exception.new('oops!')
    end
  end


  describe "#title" do
    it "returns the correct title" do
      expect(@activity.title).to eql Helpers.example_activity.title
    end
  end


  describe "#published" do
    it "returns the correct published date" do
      expect(@activity.published).to eql Helpers.example_activity.published
    end
  end


  describe "#actor" do
    it "returns the actor" do
      expect(@activity.actor).to eql Helpers.example_activity.actor
      expect(@activity.actor).to_not eql Helpers.example_activity.object
    end
  end


  describe "#verb" do
    it "returns the verb" do
      expect(@activity.verb).to eql Helpers.example_activity.verb
    end
  end


  describe "#objekt" do
    it "returns the object of the activity" do
      expect(@activity.object).to eql Helpers.example_activity.object
      expect(@activity.object).to_not eql Helpers.example_activity.actor
    end
  end


  describe "#target" do
    it "returns the target of the activity" do
      expect(@activity.target).to eql Helpers.example_activity.target
      expect(@activity.target).to_not eql Helpers.example_activity.actor
    end
  end


  describe "#uuid" do
    it "returns the UUID of the activity" do
      expect(@activity.uuid).to_not be_nil
      expect(/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/ =~ @activity.uuid).to eql 0
      expect(@activity.uuid).to eql Helpers.example_activity.uuid
    end

    it "generates a UUID if one is not supplied" do
      activity = Helpers.example_activity_without_uuid
      expect(/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/ =~ activity.uuid).to eql 0
      activity2 = Helpers.example_activity_without_uuid
      expect(activity.uuid).to_not eql activity2.uuid
      expect(activity).to_not eql activity2
    end
  end


  describe "#prototype" do
    it "returns the prototype of the activity" do
      expect(@activity.prototype).to_not be_nil
      expect(@activity.prototype).to eql Helpers.example_activity.prototype
    end

    it "generates a prototype if one is not supplied" do
      activity = Helpers.example_activity_without_prototype
      expect(activity.prototype).to eql "#{activity.actor.type}.#{activity.verb}.#{activity.object.type}"
    end
  end


  describe "#hash" do
    it "supports hash key equality" do
      a1 = RealSelf::Stream::Activity.from_hash(Helpers.example_hash)

      a2 = RealSelf::Stream::Activity.from_hash(Helpers.example_hash)

      expect(a1.object_id).to_not eql(a2.object_id)

      e = {}
      e[a2] = 123

      expect(e.include?(a1)).to eql(true)
    end
  end


  describe '#content_type' do
    it 'returns the expected content type' do
      expect(Helpers.example_activity.content_type).to eql RealSelf::ContentType::ACTIVITY
    end
  end


  describe "#to_h" do
    it "returns a hash representation of the activity" do
      hash = Helpers.example_activity.to_h
      expect(@activity.to_h).to eql hash

      json = MultiJson.encode(@activity.to_h)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(@activity).to eql activity

      # test with activity that is missing target and relations
      hash = Helpers.example_activity_without_target_or_relatives.to_h
      json = MultiJson.encode(hash)
      activity_2 = RealSelf::Stream::Activity.from_json(json)
      expect(activity_2).to eql Helpers.example_activity_without_target_or_relatives
    end
  end
end
