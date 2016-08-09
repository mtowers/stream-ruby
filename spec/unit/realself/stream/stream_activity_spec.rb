describe RealSelf::Stream::StreamActivity do

  def example_hash
    {
      :object   => {:type => "dr", :id => "1234"},
      :activity => Helpers.example_hash,
      :reasons => [
        {:type => "dr", :id => "1234"},
        {:type => "topic", :id => "4567"}
      ]
    }
  end


  def example_json
    MultiJson::encode(example_hash)
  end


  def example_stream_activity
    RealSelf::Stream::StreamActivity.new(
      RealSelf::Stream::Objekt.new('dr', 1234),
      Helpers.example_activity,
      [RealSelf::Stream::Objekt.new('dr', 1234),
       RealSelf::Stream::Objekt.new('topic', 4567)])
  end

  before :each do
    @stream_activity = example_stream_activity
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      expect(@stream_activity).to eql RealSelf::Stream::StreamActivity.from_hash(example_hash)
    end
  end

  describe '::from_json' do
    it 'takes a JSON string and returns a new instance' do
      expect(@stream_activity).to eql RealSelf::Stream::StreamActivity.from_json(example_json)
    end
  end

  describe "#new" do
    it "takes two or three parameters and returns an Objekt object" do
      expect(@stream_activity).to be_an_instance_of RealSelf::Stream::StreamActivity
    end
  end

  describe "#object" do
    it "returns an Objekt" do
     expect(@stream_activity.object).to be_an_instance_of RealSelf::Stream::Objekt
    end
  end

  describe "#activity" do
    it "returns an Activity" do
      expect(@stream_activity.activity).to be_an_instance_of RealSelf::Stream::Activity

    end
  end

  describe '#content_type' do
    it 'returns the expected content type' do
      expect(@stream_activity.content_type).to eql RealSelf::ContentType::STREAM_ACTIVITY
    end
  end


  describe '#prototype' do
    it 'returns the expected prototype' do
      expect(@stream_activity.prototype).to eql Helpers.example_activity.prototype
    end
  end


  describe '#uuid' do
    it 'returns the expected uuid' do
      expect(@stream_activity.uuid).to eql Helpers.example_activity.uuid
    end
  end


  describe "#reasons" do
    it "returns an array of Objekts" do
      expect(@stream_activity.reasons.length).to eql 2

      @stream_activity.reasons.each do |reason|
        expect(reason).to be_an_instance_of RealSelf::Stream::Objekt
      end
    end

    it "prevents duplicate reasons from being added" do
      reason = RealSelf::Stream::Objekt.new(:thing, 5678)

      @stream_activity.reasons << reason

      expect(@stream_activity.reasons.length).to eql 3

      @stream_activity.reasons << reason

      expect(@stream_activity.reasons.length).to eql 3
    end
  end

  describe "#to_h" do
    it "returns a hash" do
      hash = @stream_activity.to_h

      expect(hash[:object]).to eql ({:type => 'dr', :id => '1234'})
      expect(hash[:activity]).to eql @stream_activity.activity.to_h
      expect(hash[:reasons].length).to eql 2
      expect(hash[:reasons]).to include({:type => 'dr', :id => '1234'}, {:type => 'topic', :id => '4567'})
    end
  end

  describe "#hash" do
    it "supports hash key equality" do
      sa1 = example_stream_activity
      sa2 = example_stream_activity

      expect(sa1.object_id).to_not eql(sa2.object_id)

      e = {}
      e[sa2] = 1234
      expect(e.include?(sa1)).to eql(true)
    end
  end

  describe "#==" do
    it "compares two stream items" do
      expect(@stream_activity).to eql example_stream_activity

      other = example_stream_activity
      other.object.id = '0000'
      expect(@stream_activity).to_not eql other
    end

    it 'compares to nil' do
      expect(@stream_activity).to_not eql nil
    end

    it 'compares to other object types' do
      expect(@stream_activity).to_not eql 'string'
      expect(@stream_activity).to_not eql({:foo => 'bar'})
      expect(@stream_activity).to_not eql Exception.new('oops!')
    end
  end

  describe "#to_s" do
    it "returns a JSON string" do
      json = @stream_activity.to_s
      expect{MultiJson::encode(json)}.to_not raise_error
    end
  end

end
