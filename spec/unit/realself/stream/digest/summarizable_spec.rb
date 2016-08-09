describe RealSelf::Stream::Digest::Summarizable do
  before(:each) do
    @object          = RealSelf::Stream::Objekt.new('thing', 2345)
    @owner           = RealSelf::Stream::Objekt.new('user', 1234)
    @stream_activity = RealSelf::Stream::StreamActivity.new(
      @owner,
      Helpers.user_create_thing_activity,
      [@owner])

    @summary         = Helpers::SampleSummary.new(@object)
  end


  describe '#initialize' do
    it 'should raise an exception if the summary type does not match the constructor object type' do
      object = RealSelf::Stream::Objekt.new('bogus-thing', 2345)
      expect{Helpers::SampleSummary.new(object)}.to raise_error ArgumentError
    end
  end


  describe '#add' do
    it 'should raise an error for unknown activity types' do
      stream_activity = RealSelf::Stream::StreamActivity.new(
        @owner,
        Helpers.example_activity,
        [@owner])

      expect{@summary.add(stream_activity)}.to raise_error ArgumentError
    end
  end


  describe '#to_array' do
    it 'should return an array with the right data' do
      array = @summary.to_array
      expect(array[0]).to eql @object.to_h
      expect(array[1]).to be_instance_of(Hash)
    end
  end


  describe '#to_s' do
    it 'should return valid JSON' do
      json = @summary.to_s
      expect{MultiJson.decode(json)}.to_not raise_error
    end
  end


  describe '#==' do
    it 'should return false for dissimilar object types' do
      expect(@summary == 1).to eql false
    end

    it 'should return false for dissimilar summaries' do
      @summary.add(@stream_activity)
      summary2 = Helpers::SampleSummary.new(@object)

      expect(@summary == summary2).to eql false
    end

    it 'should return true for identical summaries' do
      summary2 = Helpers::SampleSummary.new(@object)
      @summary.add(@stream_activity)
      summary2.add(@stream_activity)

      expect(@summary == summary2).to eql true
    end
  end
end
